import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized Environment Configuration
/// ============================================================================
/// Mengelola pengambilan seluruh konfigurasi sensitif (API Key, Username, Password,
/// Base URL) dari file `.env` yang terlindungi dari Git.
///
/// Dilengkapi dengan graceful fallback ke nilai bawaan agar aplikasi tetap dapat
/// berjalan dengan aman pada lingkungan unit testing, CI/CD, atau ketika file `.env`
/// belum dibuat secara lokal.
class EnvConfig {
  static bool _initialized = false;

  /// Inisialisasi pemuatan file `.env`
  static Future<void> init() async {
    if (_initialized) return;
    try {
      await dotenv.load(fileName: ".env");
      _initialized = true;
      debugPrint("✅ EnvConfig: .env loaded successfully.");
    } catch (e) {
      _initialized = false;
      debugPrint("ℹ️ EnvConfig: .env not found or failed to load ($e). Using fallback defaults.");
    }
  }

  /// Status apakah file .env berhasil dimuat
  static bool get isInitialized => _initialized && dotenv.isInitialized;

  /// Helper untuk membaca string dari dotenv dengan fallback
  static String _get(String key, String fallback) {
    if (isInitialized) {
      final val = dotenv.env[key];
      if (val != null && val.trim().isNotEmpty) {
        return val.trim();
      }
    }
    return fallback;
  }

  // ─── OpenWeatherMap Configuration ──────────────────────────────────────────
  static String get openWeatherApiKey =>
      _get('OPENWEATHER_API_KEY', '');

  static String get openWeatherBaseUrl =>
      _get('OPENWEATHER_BASE_URL', 'https://api.openweathermap.org/data/2.5');

  // ─── Huawei FusionSolar OpenAPI Configuration ──────────────────────────────
  static String get fusionSolarBaseUrl =>
      _get('FUSIONSOLAR_BASE_URL', 'https://intl.fusionsolar.huawei.com/thirdData');

  static String get fusionSolarUsername =>
      _get('FUSIONSOLAR_USERNAME', '');

  static String get fusionSolarSystemCode =>
      _get('FUSIONSOLAR_SYSTEM_CODE', '');

  static String get fusionSolarStationMsw =>
      _get('FUSIONSOLAR_STATION_MSW', '');

  static String get fusionSolarStationKelanis =>
      _get('FUSIONSOLAR_STATION_KELANIS', '');

  // ─── Firebase Realtime Database ────────────────────────────────────────────
  static String get firebaseRtdbUrl =>
      _get('FIREBASE_RTDB_URL', '');

  // ─── Microsoft Dynamics 365 (D365) API ─────────────────────────────────────
  static String get d365ApiBaseUrl =>
      _get('D365_API_BASE_URL', '');

  static String get d365ApiToken =>
      _get('D365_API_TOKEN', '');

  // ─── Application Role Default Passwords ────────────────────────────────────
  static String get defaultAdminPassword =>
      _get('DEFAULT_ADMIN_PASSWORD', '');

  static String get defaultOperatorPassword =>
      _get('DEFAULT_OPERATOR_PASSWORD', '');

  static String get defaultMaintenancePassword =>
      _get('DEFAULT_MAINTENANCE_PASSWORD', '');

  static String get defaultGeneralPassword =>
      _get('DEFAULT_GENERAL_PASSWORD', '');

  static String get defaultOkrPassword =>
      _get('DEFAULT_OKR_PASSWORD', '');

  /// Kumpulan seluruh password default valid yang aktif dari konfigurasi .env
  static Set<String> get defaultPasswords => {
        if (defaultAdminPassword.isNotEmpty) defaultAdminPassword,
        if (defaultOperatorPassword.isNotEmpty) defaultOperatorPassword,
        if (defaultMaintenancePassword.isNotEmpty) defaultMaintenancePassword,
        if (defaultGeneralPassword.isNotEmpty) defaultGeneralPassword,
        if (defaultOkrPassword.isNotEmpty) defaultOkrPassword,
      };
}
