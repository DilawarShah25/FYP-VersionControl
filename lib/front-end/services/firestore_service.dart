import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_data.dart';

class FirestoreService {
  final CollectionReference _users = FirebaseFirestore.instance.collection('users');

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
      return []; // Return empty list on error to prevent UI crash
    }
  }
}