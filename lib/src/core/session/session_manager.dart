import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _adminKey = 'admin_logged_in';
  static const String _userKey = 'user_logged_in';
  static const String _userEmailKey = 'user_email';
  static const String _userUsernameKey = 'user_username';
  static const String _adminEmailKey = 'admin_email';

  static Future<void> setUserSession(String username, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_userKey, true);
    await prefs.setString(_userUsernameKey, username);
    await prefs.setString(_userEmailKey, email);
    await prefs.remove(_adminKey);
  }

  static Future<void> setAdminSession(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adminKey, true);
    await prefs.setString(_adminEmailKey, email);
    await prefs.remove(_userKey);
  }

  static Future<bool> isAdminLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adminKey) ?? false;
  }

  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_userKey) ?? false;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
