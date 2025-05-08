import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../NearbyDermatologist/models/clinic.dart';
import '../models/profile_data.dart';

class FirestoreService {
  final CollectionReference _users = FirebaseFirestore.instance.collection('users');
  final CollectionReference _clinics = FirebaseFirestore.instance.collection('clinics');

  Future<void> createUserProfile({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required String phoneCountryCode,
    String? imageBase64,
    required bool showContactDetails,
  }) async {
    try {
      final userDoc = {
        'id': userId,
        'name': name,
        'email': email,
        'phone': phoneCountryCode + phone,
        'phoneCountryCode': phoneCountryCode,
        'phoneNumberPart': phone,
        'image_base64': imageBase64,
        'showContactDetails': showContactDetails,
        'showEmail': showContactDetails,
        'showPhone': showContactDetails,
        // Preserve existing fields not provided in the update
        'username': FieldValue.serverTimestamp(),
        'role': FieldValue.serverTimestamp(),
        'uid': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'isEmailVerified': false,
        'lastLogin': FieldValue.serverTimestamp(),
        'lastVerificationSent': FieldValue.serverTimestamp(),
      };
      await _users.doc(userId).set(userDoc, SetOptions(merge: true));
    } catch (e) {
      print('Error creating/updating user profile: $e');
      throw e;
    }
  }

  Future<ProfileData?> getUserProfile(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) return null;
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
    } catch (e) {
      print('Error fetching user profile: $e');
      throw e;
    }
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _users.doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
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
      throw e;
    }
  }

  Future<void> addClinic(Clinic clinic) async {
    try {
      // Validate location before adding
      if (clinic.location.latitude == 0.0 && clinic.location.longitude == 0.0) {
        throw Exception('Invalid clinic location: (${clinic.location.latitude}, ${clinic.location.longitude})');
      }
      await _clinics.doc(clinic.id).set(clinic.toJson());
      print('Clinic added successfully: ${clinic.name} at (${clinic.location.latitude}, ${clinic.location.longitude})');
    } catch (e) {
      print('Error adding clinic: $e');
      throw e;
    }
  }

  Future<List<Clinic>> getAllClinics() async {
    try {
      final snapshot = await _clinics.get();
      final clinics = snapshot.docs.map((doc) {
        try {
          final clinic = Clinic.fromJson(doc.data() as Map<String, dynamic>, doc.id);
          // Log invalid locations for debugging
          if (clinic.location.latitude == 0.0 && clinic.location.longitude == 0.0) {
            print('Warning: Clinic "${clinic.name}" has invalid location: (${clinic.location.latitude}, ${clinic.location.longitude})');
          }
          return clinic;
        } catch (e) {
          print('Error parsing clinic document ${doc.id}: $e');
          // Skip invalid documents
          return null;
        }
      }).where((clinic) => clinic != null).cast<Clinic>().toList();
      print('Fetched ${clinics.length} clinics from Firestore');
      return clinics;
    } catch (e) {
      print('Error fetching clinics: $e');
      throw e;
    }
  }

  Future<List<Clinic>> getClinicsWithinRadius(LatLng userLocation, double radiusInKm) async {
    try {
      final allClinics = await getAllClinics();
      final nearbyClinics = allClinics.where((clinic) {
        // Skip clinics with invalid locations
        if (clinic.location.latitude == 0.0 && clinic.location.longitude == 0.0) {
          return false;
        }
        double distanceInKm = _calculateDistance(userLocation, clinic.location);
        return distanceInKm <= radiusInKm;
      }).toList();
      print('Found ${nearbyClinics.length} clinics within $radiusInKm km');
      return nearbyClinics;
    } catch (e) {
      print('Error filtering clinics by radius: $e');
      throw e;
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Radius of the Earth in kilometers
    double lat1 = point1.latitude * (pi / 180);
    double lon1 = point1.longitude * (pi / 180);
    double lat2 = point2.latitude * (pi / 180);
    double lon2 = point2.longitude * (pi / 180);

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}