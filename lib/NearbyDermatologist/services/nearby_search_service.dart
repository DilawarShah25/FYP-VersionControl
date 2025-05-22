import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/dermatologist.dart';

class NearbySearchService {
  // // static const String _apiKey = 'AlzaSy9-Dp095SVFgJjVLuB27OnQrEFeXUJ3sEZ'; // GoMaps API key
// // static const String _baseUrl = 'https://app.gomaps.pro/api/places/nearby'; // GoMaps endpoint

  static const String _apiKey = 'AIzaSyA9jG5b3qOz7y-GXNaN3kjOxhnzC87VULQ'; // Google Map API key
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'; // Google Places API endpoint
  static const int _radius = 20000; // 20km radius
  String? _nextPageToken; // For pagination

  Future<List<Dermatologist>> getNearbyDermatologists(LatLng location, {bool fetchMore = false}) async {
    final String url = fetchMore && _nextPageToken != null
        ? '$_baseUrl?pagetoken=$_nextPageToken&key=$_apiKey'
        : '$_baseUrl?location=${location.latitude},${location.longitude}&radius=$_radius&name=dermatologist|trichologist|hair%20clinic&key=$_apiKey';

    print("Fetching dermatologists and hair specialists with URL: $url");

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          print("API Response: $json");

          _nextPageToken = json['next_page_token'] ?? null;

          if (json['results'] != null) {
            final results = json['results'] as List;
            print("Found ${results.length} dermatologists or hair specialists");
            return results.map((result) => Dermatologist.fromJson(result)).toList();
          } else {
            print("No places found in response");
            return [];
          }
        } else {
          print("HTTP error: ${response.statusCode} - ${response.body}");
          if (response.body.contains('API key')) {
            throw Exception("Invalid API key. Please check your GoMaps API key.");
          }
          return [];
        }
      } catch (e) {
        print("Error fetching dermatologists or hair specialists (attempt $attempt): $e");
        if (attempt == 3) return [];
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return [];
  }

  bool get hasMoreResults => _nextPageToken != null;

  void resetPagination() {
    _nextPageToken = null;
  }
}