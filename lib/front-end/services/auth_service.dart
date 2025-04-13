import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import '../utils/image_utils.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      print('Starting registration for: $email');
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        print('❌ User creation failed: No user returned');
        return {'error': 'User creation failed', 'image_base64': '', 'uid': null};
      }

      print('User created: ${user.uid}. Sending verification email...');
      await user.sendEmailVerification();

      String uid = user.uid;
      String imageBase64 = '';

      if (profileImage != null) {
        print('Converting profile image to base64 for: $uid');
        imageBase64 = await ImageUtils.convertImageToBase64(profileImage) ?? '';
        if (imageBase64.isEmpty) {
          print('❌ Image conversion failed');
          await user.delete();
          return {'error': 'Image conversion failed', 'image_base64': '', 'uid': null};
        }
      }

      Map<String, dynamic> userData = {
        'name': name.trim(),
        'email': email.trim(),
        'role': role,
        'phoneCountryCode': phoneCountryCode,
        'phoneNumberPart': phoneNumberPart,
        'image_base64': imageBase64,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isEmailVerified': false,
        'lastLogin': FieldValue.serverTimestamp(),
        'lastVerificationSent': FieldValue.serverTimestamp(),
      };

      print('Saving user data to Firestore: $uid');
      await _firestore.collection('users').doc(uid).set(userData);
      print('✅ Registration successful for: $email');
      return {'error': null, 'image_base64': imageBase64, 'uid': uid};
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak.';
          break;
        default:
          errorMessage = 'Registration failed: ${e.message}';
      }
      print('❌ Registration error: $errorMessage');
      return {'error': errorMessage, 'image_base64': '', 'uid': null};
    } catch (e) {
      print('❌ Unexpected registration error: $e');
      return {'error': 'Unexpected error: $e', 'image_base64': '', 'uid': null};
    }
  }

  Future<Map<String, dynamic>> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('Attempting login for: $email');
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        print('❌ Login failed: No user returned');
        return {'error': 'Login failed', 'user': null};
      }

      if (!user.emailVerified) {
        print('❌ Email not verified for: $email');
        await _auth.signOut();
        return {'error': 'Please verify your email first.', 'user': null};
      }

      print('Updating last login for: $email');
      await _firestore.collection('users').doc(user.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      print('✅ Login successful for: $email');
      return {'error': null, 'user': user};
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        default:
          errorMessage = 'Login failed: ${e.message}';
      }
      print('❌ Login error: $errorMessage');
      return {'error': errorMessage, 'user': null};
    } catch (e) {
      print('❌ Unexpected login error: $e');
      return {'error': 'Unexpected error: $e', 'user': null};
    }
  }

  Future<void> signOut() async {
    try {
      print('Signing out user');
      await _auth.signOut();
      print('✅ Sign out successful');
    } catch (e) {
      print('❌ Sign out error: $e');
      throw Exception('Sign out failed: $e');
    }
  }

  User? getCurrentUser() {
    final user = _auth.currentUser;
    print('Current user: ${user?.email ?? "None"}');
    return user;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<bool> isEmailVerified() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('❌ No user signed in');
        return false;
      }

      await user.reload();
      user = _auth.currentUser;

      if (user != null && user.emailVerified) {
        print('✅ Email verified for: ${user.email}');
        await _firestore.collection('users').doc(user.uid).update({
          'isEmailVerified': true,
          'emailVerifiedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      print('Email not verified for: ${user?.email}');
      return false;
    } catch (e) {
      print('❌ Error checking email verification: $e');
      return false;
    }
  }

  Future<String?> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('❌ No user signed in');
        return 'No user signed in.';
      }
      if (user.emailVerified) {
        print('✅ Email already verified for: ${user.email}');
        return 'Email already verified.';
      }

      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        print('❌ User data not found in Firestore');
        return 'User data not found.';
      }

      final lastSent = (doc.data() as Map<String, dynamic>)['lastVerificationSent'] as Timestamp?;
      if (lastSent != null && DateTime.now().difference(lastSent.toDate()).inSeconds < 30) {
        print('⏳ Rate limit: Wait before resending verification email');
        return 'Please wait 30 seconds before resending.';
      }

      print('Resending verification email to: ${user.email}');
      await user.sendEmailVerification();
      await _firestore.collection('users').doc(user.uid).update({
        'lastVerificationSent': FieldValue.serverTimestamp(),
      });
      print('✅ Verification email resent');
      return null;
    } catch (e) {
      print('❌ Error resending verification email: $e');
      return 'Error resending email: $e';
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      print('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email.trim());
      print('✅ Password reset email sent');
      return null;
    } catch (e) {
      print('❌ Error sending password reset email: $e');
      return 'Error sending password reset email: $e';
    }
  }

  Future<Map<String, dynamic>> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        print('✅ User data fetched for: $uid');
        return doc.data() as Map<String, dynamic>;
      }
      print('❌ User data not found for: $uid');
      return {'error': 'User data not found'};
    } catch (e) {
      print('❌ Error fetching user data: $e');
      return {'error': 'Error fetching user data: $e'};
    }
  }

  Future<String?> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      print('Updating user data for: $uid');
      await _firestore.collection('users').doc(uid).update(data);
      print('✅ User data updated successfully');
      return null;
    } catch (e) {
      print('❌ Error updating user data: $e');
      return 'Error updating user data: $e';
    }
  }
}