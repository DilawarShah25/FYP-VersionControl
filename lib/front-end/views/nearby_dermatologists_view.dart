import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/app_theme.dart';

class NearbyDermatologistsView extends StatefulWidget {
  const NearbyDermatologistsView({super.key});

  @override
  State<NearbyDermatologistsView> createState() => _NearbyDermatologistsViewState();
}

class _NearbyDermatologistsViewState extends State<NearbyDermatologistsView> {
  static const String apiKey = "AlzaSydlT3PcvzpVjh2G3km77z4aZcLMR_TBqRB";
  final List<Map<String, dynamic>> _dermatologists = [];
  LatLng? currentPosition;
  String searchTerm = "";

  @override
  void initState() {
    super.initState();
    _fetchCurrentPosition();
  }

  Future<void> _fetchCurrentPosition() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(115.0),
        child: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Padding(
            padding: const EdgeInsets.only(right: 50.0, top: 15.0),
            child: Center(
              child: Text(
                'Nearby Dermatologists',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100.0),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 50.0,
              decoration: const BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: TextField(
                  onChanged: _onSearch,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search for dermatologists',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[400],
                    ),
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
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      )
          : _dermatologists.isEmpty
          ? Center(
        child: Text(
          'No dermatologists found nearby.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      )
          : ListView.builder(
        itemCount: _dermatologists.length,
        itemBuilder: (context, index) {
          final dermatologist = _dermatologists[index];
          return ListTile(
            leading: const Icon(
              Icons.local_hospital,
              color: AppTheme.primaryColor,
            ),
            title: Text(
              dermatologist['name'],
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              dermatologist['address'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
            ),
            trailing: Text(
              dermatologist['rating'].toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}