import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_data.dart';
import '../services/firestore_service.dart';

class ProfileController {
  final FirestoreService _firestoreService = FirestoreService();

  Future<List<ProfileData>> getAllProfiles() async {
    return await _firestoreService.getAllProfiles();
  }

  Future<void> updateProfilePrivacy(
      String uid, {
        bool? showContactDetails,
        bool? showEmail,
        bool? showPhone,
        bool? showImage,
      }) async {
    final data = <String, dynamic>{};
    if (showContactDetails != null) data['showContactDetails'] = showContactDetails;
    if (showEmail != null) data['showEmail'] = showEmail;
    if (showPhone != null) data['showPhone'] = showPhone;
    if (showImage != null) data['showImage'] = showImage;

    await _firestoreService.updateProfile(uid, data);
  }
}