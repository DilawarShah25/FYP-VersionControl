import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> _generateUniqueUsername(String fullName) async {
    String baseName = fullName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (baseName.isEmpty) baseName = 'user';
    baseName = baseName.length > 12 ? baseName.substring(0, 12) : baseName;

    List<String> formats = [
      '@$baseName',
      '@${baseName.replaceAll(RegExp(r'[^a-z0-9]'), '_')}',
      '@${baseName}_',
    ];

    Random random = Random();
    String selectedFormat = formats[random.nextInt(formats.length)];
    String username;
    bool isUnique = false;
    int attempt = 0;

    do {
      String digits = (random.nextInt(900) + 100).toString();
      username = selectedFormat + digits;
      if (username.length > 16) {
        username = '@' + baseName.substring(0, 12) + digits;
      }
      final snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      isUnique = snapshot.docs.isEmpty;
      attempt++;
      if (attempt > 10) {
        digits = (random.nextInt(9000) + 1000).toString();
        username = '@$baseName$digits';
      }
    } while (!isUnique);

    return username;
  }

  Future<Map<String, String?>> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String phoneCountryCode,
    required String phoneNumberPart,
    required String role,
  }) async {
    try {
      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
        print('Validation failed: Invalid email format');
        return {'error': 'Invalid email format'};
      }
      if (!RegExp(r'^[1-9][0-9]{5,11}$').hasMatch(phoneNumberPart)) {
        print('Validation failed: Phone number must be 6-12 digits, no leading 0');
        return {'error': 'Phone number must be 6-12 digits, no leading 0'};
      }
      if (!RegExp(r'^\+[1-9][0-9]{0,3}$').hasMatch(phoneCountryCode)) {
        print('Validation failed: Invalid country code');
        return {'error': 'Invalid country code'};
      }
      if (name.length < 2) {
        print('Validation failed: Name must be at least 2 characters');
        return {'error': 'Name must be at least 2 characters'};
      }
      if (!['User', 'Admin'].contains(role)) {
        print('Validation failed: Invalid role');
        return {'error': 'Invalid role'};
      }

      print('Creating Firebase Auth user for $email');
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user == null) {
        print('Failed to create user: No user returned');
        return {'error': 'Failed to create user'};
      }

      String username = await _generateUniqueUsername(name);
      print('Generated username: $username');

      print('Sending verification email to $email');
      await user.sendEmailVerification();

      final phone = phoneCountryCode + phoneNumberPart;
      final now = Timestamp.now();
      final userDoc = {
        'id': user.uid, // Added to match ProfileData
        'name': name,
        'email': email,
        'username': username,
        'role': role,
        'phoneCountryCode': phoneCountryCode,
        'phoneNumberPart': phoneNumberPart,
        'phone': phone,
        'uid': user.uid,
        'createdAt': now,
        'isEmailVerified': false,
        'lastLogin': now,
        'lastVerificationSent': now,
        'image_base64': null,
        'showContactDetails': true,
        'showEmail': true,
        'showPhone': true,
      };

      print('Saving user document for UID: ${user.uid}');
      print('User document content: $userDoc');

      await _firestore.collection('users').doc(user.uid).set(userDoc);

      print('User document saved successfully');
      return {'error': null};
    } catch (e) {
      print('Registration error: $e');
      String errorMessage;
      if (e is FirebaseAuthException) {
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
            errorMessage = 'Authentication error: ${e.message}';
        }
      } else if (e is FirebaseException && e.code == 'permission-denied') {
        errorMessage = 'Permission denied: Check user document fields and security rules.';
      } else {
        errorMessage = 'Unexpected error: ${e.toString()}';
      }
      return {'error': errorMessage};
    }
  }

  Future<bool> isEmailVerified() async {
    try {
      await _auth.currentUser?.reload();
      bool verified = _auth.currentUser?.emailVerified ?? false;
      print('Email verification status: $verified');
      if (verified) {
        await _firestore.collection('users').doc(_auth.currentUser?.uid).update({
          'isEmailVerified': true,
          'emailVerifiedAt': Timestamp.now(),
        });
      }
      return verified;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  Future<String?> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        print('Resending verification email to ${user.email}');
        await user.sendEmailVerification();
        await _firestore.collection('users').doc(user.uid).update({
          'lastVerificationSent': Timestamp.now(),
        });
        return null;
      }
      return 'User is already verified or not logged in.';
    } catch (e) {
      print('Error resending verification email: $e');
      return 'Failed to resend verification email: ${e.toString()}';
    }
  }

  Future<Map<String, String?>> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user == null) {
        return {'error': 'Failed to sign in'};
      }

      if (!user.emailVerified) {
        return {'error': 'Please verify your email first.'};
      }

      return {'error': null};
    } catch (e) {
      print('Sign-in error: $e');
      String errorMessage;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email format.';
            break;
          default:
            errorMessage = 'Sign-in failed: ${e.message}';
        }
      } else {
        errorMessage = 'An unexpected error occurred.';
      }
      return {'error': errorMessage};
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      print('Password reset error: $e');
      return 'Failed to send password reset email.';
    }
  }
}