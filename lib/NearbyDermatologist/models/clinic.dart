import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Clinic {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final String userId;
  final Timestamp createdAt;

  Clinic({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.userId,
    required this.createdAt,
  });

  factory Clinic.fromJson(Map<String, dynamic> json, String id) {
    return Clinic(
      id: id,
      name: json['name'] ?? 'Unknown',
      address: json['address'] ?? 'No address',
      location: LatLng(
        json['location']['latitude'] ?? 0.0,
        json['location']['longitude'] ?? 0.0,
      ),
      userId: json['userId'] ?? '',
      createdAt: json['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'userId': userId,
      'createdAt': createdAt,
    };
  }
}