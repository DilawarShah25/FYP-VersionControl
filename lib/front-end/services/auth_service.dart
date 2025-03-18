import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Register user with email and password, returns error, imageUrl, and uid
  Future<Map<String, dynamic>> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String phoneCountryCode,
    required String phoneNumberPart,
    required String role,
    File? profileImage,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        return {'error': 'User creation failed: No user returned', 'imageUrl': '', 'uid': null};
      }

      await user.sendEmailVerification();

      String uid = user.uid;
      String imageUrl = '';

      if (profileImage != null) {
        try {
          Reference storageRef = _storage.ref().child('profile_images/$uid.jpg');
          UploadTask uploadTask = storageRef.putFile(profileImage, SettableMetadata(contentType: "image/jpeg"));
          TaskSnapshot snapshot = await uploadTask;
          imageUrl = await snapshot.ref.getDownloadURL();
        } catch (e) {
          await user.delete();
          return {'error': 'Image upload failed: ${e.toString()}', 'imageUrl': '', 'uid': null};
        }
      }

      Map<String, dynamic> userData = {
        'name': name.trim(),
        'email': email.trim(),
        'role': role,
        'phoneCountryCode': phoneCountryCode,
        'phoneNumberPart': phoneNumberPart,
        'imageUrl': imageUrl,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isEmailVerified': false,
        'lastLogin': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(uid).set(userData);

      print('User data saved to Firestore: $userData');
      return {'error': null, 'imageUrl': imageUrl, 'uid': uid};
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'The email address is already in use by another account.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        default:
          errorMessage = 'Registration failed: ${e.message}';
      }
      return {'error': errorMessage, 'imageUrl': '', 'uid': null};
    } catch (e) {
      return {'error': 'Unexpected error during registration: ${e.toString()}', 'imageUrl': '', 'uid': null};
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception('Sign out failed: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during sign out: ${e.toString()}');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check email verification status and update Firestore
  Future<bool> isEmailVerified() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      await user.reload();
      user = _auth.currentUser;

      if (user != null && user.emailVerified) {
        await _firestore.collection('users').doc(user.uid).update({
          'isEmailVerified': true,
          'emailVerifiedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking/updating email verification status: $e');
      return false;
    }
  }

  // Resend email verification
  Future<String?> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return 'No user is currently signed in.';
      if (user.emailVerified) return 'Email is already verified.';

      final lastSent = (await _firestore.collection('users').doc(user.uid).get())['lastVerificationSent'] as Timestamp?;
      if (lastSent != null && DateTime.now().difference(lastSent.toDate()).inMinutes < 1) {
        return 'Please wait before requesting another verification email.';
      }

      await user.sendEmailVerification();
      await _firestore.collection('users').doc(user.uid).update({
        'lastVerificationSent': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return 'Error resending verification email: ${e.message}';
    } catch (e) {
      return 'Unexpected error: ${e.toString()}';
    }
  }

  // Update user profile in Firestore
  Future<String?> updateUserProfile({
    required String uid,
    String? name,
    String? phoneCountryCode,
    String? phoneNumberPart,
    File? profileImage,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name.trim();
      if (phoneCountryCode != null) updates['phoneCountryCode'] = phoneCountryCode;
      if (phoneNumberPart != null) updates['phoneNumberPart'] = phoneNumberPart;

      if (profileImage != null) {
        Reference storageRef = _storage.ref().child('profile_images/$uid.jpg');
        await storageRef.putFile(profileImage, SettableMetadata(contentType: "image/jpeg"));
        String imageUrl = await storageRef.getDownloadURL();
        updates['imageUrl'] = imageUrl;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
      }
      return null;
    } catch (e) {
      return 'Error updating profile: ${e.toString()}';
    }
  }

  // Update user data in Firestore (generic update)
  Future<String?> updateUserData(String uid, Map<String, dynamic> updatedData) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != uid) {
        return 'Unauthorized: No user signed in or UID mismatch';
      }

      Map<String, dynamic> sanitizedData = {};
      updatedData.forEach((key, value) {
        if (value != null) sanitizedData[key] = (value is String) ? value.trim() : value;
      });

      if (sanitizedData.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(sanitizedData);
        return null;
      }
      return 'No valid data provided to update';
    } catch (e) {
      return 'Error updating user data: ${e.toString()}';
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) return doc.data() as Map<String, dynamic>;
      return {'error': 'User data not found'};
    } catch (e) {
      return {'error': 'Error fetching user data: ${e.toString()}'};
    }
  }

  // Stream of user data from Firestore
  Stream<DocumentSnapshot> getUserDataStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }
}