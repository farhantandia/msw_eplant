import 'package:shared_preferences/shared_preferences.dart';
import 'package:msw_eplant/models/role.dart';

class AuthService {
  static const _roleKey = 'session_role';
  static const _timestampKey = 'session_timestamp';
  static const _sessionDuration = Duration(days: 15);

  static Future<bool> hasValidSession() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_timestampKey);
    if (timestamp == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    return age < _sessionDuration.inMilliseconds;
  }

  static Future<UserRole?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_roleKey);
    if (role == null) return null;
    return UserRole.values.firstWhere(
      (r) => r.label == role,
      orElse: () => UserRole.general,
    );
  }

  static Future<void> saveSession(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.label);
    await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    await prefs.remove(_timestampKey);
  }

  // Simulation — nanti ganti dengan SHA-256 + Firestore
  static Future<bool> verifyPassword(UserRole role, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return password == 'admin123' || password == '1234';
  }
}
