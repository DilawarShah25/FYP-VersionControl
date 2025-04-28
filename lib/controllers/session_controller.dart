import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionController {
  static const String _lastLoginKey = 'last_login_timestamp';
  static const int sessionTimeoutDays = 7; // Configurable timeout

  // Save the current timestamp as last login
  Future<void> saveLastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_lastLoginKey, now);
    debugPrint('Saved last login: ${DateTime.fromMillisecondsSinceEpoch(now)}');
  }

  // Check if the session is valid
  Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogin = prefs.getInt(_lastLoginKey);
    if (lastLogin == null) {
      debugPrint('No last login found');
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final timeoutMillis = sessionTimeoutDays * 24 * 60 * 60 * 1000; // Days to milliseconds
    final isValid = (now - lastLogin) < timeoutMillis;
    debugPrint('Session valid: $isValid, Last login: ${DateTime.fromMillisecondsSinceEpoch(lastLogin)}');
    return isValid;
  }

  // Clear session data
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLoginKey);
    debugPrint('Cleared session');
  }
}