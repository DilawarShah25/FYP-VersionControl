import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../NearbyDermatologist/models/clinic.dart';
import '../models/profile_data.dart';


class FirestoreService {
  final CollectionReference _users = FirebaseFirestore.instance.collection('users');
  final CollectionReference _clinics = FirebaseFirestore.instance.collection('clinics');

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).set(data, SetOptions(merge: true));
  }

  Future<List<ProfileData>> getAllProfiles() async {
    try {
      final snapshot = await _users.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final showContactDetails = data['showContactDetails'] as bool? ?? true;
        return ProfileData(
          id: doc.id,
          name: data['name'] as String? ?? 'Unknown',
          email: showContactDetails ? (data['email'] as String? ?? '') : '',
          phoneCountryCode: showContactDetails ? (data['phoneCountryCode'] as String? ?? '+1') : '+1',
          phoneNumberPart: showContactDetails ? (data['phoneNumberPart'] as String? ?? '') : '',
          role: data['role'] as String? ?? 'User',
          imageBase64: data['image_base64'] as String?,
          showContactDetails: showContactDetails,
          showEmail: showContactDetails ? (data['showEmail'] as bool? ?? true) : true,
          showPhone: showContactDetails ? (data['showPhone'] as bool? ?? true) : true,
        );
      }).toList();
    } catch (e) {
      print('Error fetching profiles: $e');
      return [];
    }
  }

  Future<void> addClinic(Clinic clinic) async {
    try {
      await _clinics.doc(clinic.id).set(clinic.toJson());
    } catch (e) {
      print('Error adding clinic: $e');
      throw e;
    }
  }

  Future<List<Clinic>> getAllClinics() async {
    try {
      final snapshot = await _clinics.get();
      return snapshot.docs.map((doc) => Clinic.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print('Error fetching clinics: $e');
      return [];
    }
  }

  Future<List<Clinic>> getClinicsWithinRadius(LatLng userLocation, double radiusInKm) async {
    try {
      final allClinics = await getAllClinics();
      return allClinics.where((clinic) {
        double distanceInKm = _calculateDistance(userLocation, clinic.location);
        return distanceInKm <= radiusInKm;
      }).toList();
    } catch (e) {
      print('Error filtering clinics by radius: $e');
      return [];
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Radius of the Earth in kilometers
    double lat1 = point1.latitude * (pi / 180); // Convert to radians, using pi from dart:math
    double lon1 = point1.longitude * (pi / 180);
    double lat2 = point2.latitude * (pi / 180);
    double lon2 = point2.longitude * (pi / 180);

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Distance in kilometers
  }
}