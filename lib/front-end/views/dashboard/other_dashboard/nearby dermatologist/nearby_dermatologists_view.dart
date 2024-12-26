import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NearbyDermatologistsView extends StatefulWidget {
  const NearbyDermatologistsView({super.key});

  @override
  State<NearbyDermatologistsView> createState() => _NearbyDermatologistsViewState();
}

class _NearbyDermatologistsViewState extends State<NearbyDermatologistsView> {
  static const String apiKey = "AIzaSyAOVYRIgupAurZup5y1PRh8Ismb1A3lLao";
  final List<Map<String, dynamic>> _dermatologists = [];
  LatLng? currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchCurrentPosition();
  }

  Future<void> _fetchCurrentPosition() async {
    // Simulate fetching the current location (use a location plugin for real GPS data)
    setState(() {
      currentPosition = const LatLng(37.7749, -122.4194); // Example: San Francisco
    });
    if (currentPosition != null) {
      await _fetchNearbyDermatologists();
    }
  }

  Future<void> _fetchNearbyDermatologists() async {
    final String url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        "?location=${currentPosition!.latitude},${currentPosition!.longitude}"
        "&radius=5000&type=doctor&keyword=dermatologist&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _dermatologists.clear();
          for (var result in data['results']) {
            _dermatologists.add({
              'name': result['name'],
              'address': result['vicinity'],
              'rating': result['rating'] ?? 'No rating',
            });
          }
        });
      } else {
        debugPrint("Failed to fetch data: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Dermatologists'),
        backgroundColor: Colors.blue,
      ),
      body: currentPosition == null
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _dermatologists.isEmpty
          ? const Center(
        child: Text(
          'No dermatologists found nearby.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: _dermatologists.length,
        itemBuilder: (context, index) {
          final dermatologist = _dermatologists[index];
          return ListTile(
            leading: const Icon(Icons.local_hospital),
            title: Text(dermatologist['name']),
            subtitle: Text(dermatologist['address']),
            trailing: Text(
              dermatologist['rating'].toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}

