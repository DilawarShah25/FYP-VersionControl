import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class NearbyDermatologistsController extends ChangeNotifier {
  static const String apiKey = "AIzaSyAOVYRIgupAurZup5y1PRh8Ismb1A3lLao";

  LatLng? currentPosition;
  bool isLoading = false;
  final List<Marker> markers = [];

  Future<void> getCurrentLocation() async {
    isLoading = true;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      currentPosition = LatLng(position.latitude, position.longitude);
      await fetchNearbyDermatologists();
    } catch (e) {
      debugPrint("Error getting location: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNearbyDermatologists() async {
    if (currentPosition == null) return;

    final String url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        "?location=${currentPosition!.latitude},${currentPosition!.longitude}"
        "&radius=5000&type=doctor&keyword=dermatologist&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        markers.clear();
        for (var result in data['results']) {
          final LatLng position = LatLng(
            result['geometry']['location']['lat'],
            result['geometry']['location']['lng'],
          );
          final String name = result['name'];
          final String address = result['vicinity'] ?? 'No address available';

          markers.add(
            Marker(
              markerId: MarkerId(name),
              position: position,
              infoWindow: InfoWindow(
                title: name,
                snippet: address,
              ),
            ),
          );
        }
        notifyListeners();
      } else {
        debugPrint("Failed to fetch data: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }
}