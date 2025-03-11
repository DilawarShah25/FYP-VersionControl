import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Register user with email and password, returns error and imageUrl
  Future<Map<String, dynamic>> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    File? profileImage,
  }) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      String uid = userCredential.user?.uid ?? '';
      String imageUrl = '';

      // Upload profile image if provided
      if (profileImage != null) {
        try {
          Reference storageRef = _storage.ref().child('profile_images/$uid.jpg');
          await storageRef.putFile(profileImage, SettableMetadata(contentType: "image/jpeg"));
          imageUrl = await storageRef.getDownloadURL();
        } catch (e) {
          return {'error': 'Image upload failed: ${e.toString()}', 'imageUrl': ''};
        }
      }

      // Save user data to Firestore
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'imageUrl': imageUrl,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isEmailVerified': false,
      });

      return {'error': null, 'imageUrl': imageUrl}; // Success
    } catch (e) {
      return {'error': e.toString(), 'imageUrl': ''}; // Error
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check email verification status and update Firestore
  Future<bool> isEmailVerified() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    await user.reload(); // Refresh user data
    user = _auth.currentUser; // Get updated user instance

    // Ensure user is not null before checking emailVerified
    if (user != null && user.emailVerified) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'isEmailVerified': true,
        });
      } catch (e) {
        print('Error updating email verification status: $e');
      }
      return true;
    }
    return false;
  }

  // Resend email verification
  Future<String?> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return null; // Success
      } else {
        return 'User not found or already verified.';
      }
    } catch (e) {
      return 'Error resending verification email: ${e.toString()}';
    }
  }
}
