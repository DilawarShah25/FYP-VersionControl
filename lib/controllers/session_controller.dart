import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionController {
  static const String _lastLoginKey = 'last_login_timestamp';
  static const int sessionTimeoutDays = 7; // 7-day timeout
  static SharedPreferences? _prefs;
  static bool _isInitializing = false;

  static Future<void> init() async {
    if (_prefs != null || _isInitializing) return; // Prevent multiple initializations
    _isInitializing = true;
    try {
      _prefs = await SharedPreferences.getInstance();
      debugPrint('SharedPreferences initialized');
    } catch (e) {
      debugPrint('Failed to initialize SharedPreferences: $e');
      _prefs = null; // Reset to allow retry
      rethrow; // Allow caller to handle the error
    } finally {
      _isInitializing = false;
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await init();
    }
    if (_prefs == null) {
      throw Exception('SharedPreferences initialization failed');
    }
    return _prefs!;
  }

  Future<void> saveLastLogin() async {
    try {
      final prefs = await _getPrefs();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_lastLoginKey, now);
      debugPrint('Saved last login: ${DateTime.fromMillisecondsSinceEpoch(now)}');
    } catch (e) {
      debugPrint('Failed to save last login: $e');
    }
  }

  Future<bool> isSessionValid() async {
    try {
      final prefs = await _getPrefs();
      final lastLogin = prefs.getInt(_lastLoginKey);
      if (lastLogin == null) {
        debugPrint('No last login found');
        return false;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final timeoutMillis = sessionTimeoutDays * 24 * 60 * 60 * 1000;
      final isValid = (now - lastLogin) < timeoutMillis;
      debugPrint(
          'Session valid: $isValid, Last login: ${DateTime.fromMillisecondsSinceEpoch(lastLogin)}');
      return isValid;
    } catch (e) {
      debugPrint('Error checking session validity: $e');
      return false; // Assume session is invalid on error
    }
  }

  Future<void> clearSession() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_lastLoginKey);
      debugPrint('Cleared session');
    } catch (e) {
      debugPrint('Failed to clear session: $e');
    }
  }
}