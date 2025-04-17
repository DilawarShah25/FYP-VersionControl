import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_data.dart';

class FirestoreService {
  final CollectionReference _users = FirebaseFirestore.instance.collection('users');

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).set(data, SetOptions(merge: true));
  }

  Future<List<ProfileData>> getAllProfiles() async {
    final snapshot = await _users.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ProfileData(
        id: doc.id,
        name: data['name'],
        email: data['email'],
        phoneCountryCode: data['phoneCountryCode'],
        phoneNumberPart: data['phoneNumberPart'],
        role: data['role'],
      );
    }).toList();
  }
}