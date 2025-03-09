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
  static const String apiKey = "AlzaSydlT3PcvzpVjh2G3km77z4aZcLMR_TBqRB";
  final List<Map<String, dynamic>> _dermatologists = [];
  LatLng? currentPosition;
  String searchTerm = ""; // Add a variable to store the search term

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

  void _onSearch(String value) {
    setState(() {
      searchTerm = value;
    });
    // Implement search logic here based on searchTerm
    // You can filter the _dermatologists list based on the search term
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(115.0), // Height of the AppBar
        child: AppBar(
          // backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF004e92),
                  Color(0xFF000428),
                ],
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Padding(
            padding: EdgeInsets.only(right: 50.0, top: 15.0),
            child: Center(
              child: Text(
                'Nearby Dermatologists',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100.0), // Increased height for search bar
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 50.0,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: TextField(
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search for dermatologists',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
        ),
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