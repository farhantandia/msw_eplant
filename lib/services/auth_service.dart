import 'package:shared_preferences/shared_preferences.dart';
import 'package:msw_eplant/models/role.dart';

class AuthService {
  static const _roleKey = 'session_role';
  static const _timestampKey = 'session_timestamp';
  static const _sessionDuration = Duration(days: 15);

  static const _defaultPasswords = {'admin123', '1234'};

  static String _passwordKey(String scope) => 'password_$scope';

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

  /// Simpan password untuk scope tertentu.
  /// Scope: operation, maintenance, general, okr_editor, admin.
  static Future<void> setPassword(String scope, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordKey(scope), password);
  }

  static Future<String?> getPassword(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey(scope));
  }

  static Future<void> clearPassword(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passwordKey(scope));
  }

  /// Verifikasi password per scope berdasarkan SharedPreferences.
  /// Scope yang belum di-set dianggap menggunakan password default.
  static Future<bool> verifyPasswordScope(String scope, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final stored = await getPassword(scope);
    if (stored != null && stored.isNotEmpty) return stored == password;
    return _defaultPasswords.contains(password);
  }

  // Simulation — nanti ganti dengan SHA-256 + Firestore
  static Future<bool> verifyPassword(UserRole role, String password) {
    return verifyPasswordScope(role.label.toLowerCase(), password);
  }
}