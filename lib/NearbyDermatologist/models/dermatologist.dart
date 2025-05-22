import 'package:google_maps_flutter/google_maps_flutter.dart';

class Dermatologist {
  final String name;
  final String address;
  final LatLng location;

  Dermatologist({
    required this.name,
    required this.address,
    required this.location,
  });

  factory Dermatologist.fromJson(Map<String, dynamic> json) {
    return Dermatologist(
      name: json['name'] ?? 'Unknown',
      address: json['address'] ?? 'No address', // Adjust based on GoMaps response
      location: LatLng(
        json['geometry']?['location']?['lat'] ?? 0.0, // Adjust based on GoMaps response
        json['geometry']?['location']?['lng'] ?? 0.0, // Adjust based on GoMaps response
      ),
    );
  }
}