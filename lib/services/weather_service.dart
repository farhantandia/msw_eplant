import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:msw_eplant/config/env_config.dart';

/// Lokasi operasional MSW ePlant untuk pemantauan cuaca
enum WeatherLocation {
  mswTanjung(
    id: 'msw',
    name: 'PLTU MSW (Tanjung)',
    shortName: 'MSW Tanjung',
    cityQuery: 'Tanjung,ID',
    lat: -2.1856,
    lon: 115.3889,
    region: 'Tabalong, Kalimantan Selatan',
    plantCapacity: '400 kWp Solar PV · 2x30 MW CFPP',
  ),
  kelanis(
    id: 'kelanis',
    name: 'Terminal Kelanis',
    shortName: 'Kelanis Port',
    cityQuery: 'Kelanis,ID',
    lat: -2.3500,
    lon: 115.1000,
    region: 'Barito Selatan, Kalimantan Tengah',
    plantCapacity: '468 kWp Solar PV · Coal Barge Port',
  );

  final String id;
  final String name;
  final String shortName;
  final String cityQuery;
  final double lat;
  final double lon;
  final String region;
  final String plantCapacity;

  const WeatherLocation({
    required this.id,
    required this.name,
    required this.shortName,
    required this.cityQuery,
    required this.lat,
    required this.lon,
    required this.region,
    required this.plantCapacity,
  });
}

/// Status evaluasi risiko operasional plant
enum PlantRiskLevel {
  safe('AMAN', Color(0xFF00E5A0), Icons.check_circle_outline),
  caution('WASPADA', Color(0xFFFFB020), Icons.warning_amber_rounded),
  warning('BAHAYA / RISIKO TINGGI', Color(0xFFFF4D6A), Icons.error_outline_rounded);

  final String label;
  final Color color;
  final IconData icon;

  const PlantRiskLevel(this.label, this.color, this.icon);
}

class WeatherService {
  static String get _apiKey => EnvConfig.openWeatherApiKey;
  static String get _baseUrl => EnvConfig.openWeatherBaseUrl;

  /// Default HTTP client injectable for unit testing
  static http.Client client = http.Client();

  /// Fetches real-time weather from OpenWeatherMap for a given plant location
  static Future<Map<String, dynamic>?> fetchWeather({
    WeatherLocation location = WeatherLocation.mswTanjung,
  }) async {
    try {
      // Primary: lat/lon coordinate query (paling akurat untuk wilayah plant & pelabuhan)
      final url = Uri.parse(
        '$_baseUrl/weather?lat=${location.lat}&lon=${location.lon}&units=metric&appid=$_apiKey',
      );
      final response = await client.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        // Fallback: city query
        final fallbackUrl = Uri.parse(
          '$_baseUrl/weather?q=${location.cityQuery}&units=metric&appid=$_apiKey',
        );
        final fbRes = await client.get(fallbackUrl).timeout(const Duration(seconds: 10));
        if (fbRes.statusCode == 200) {
          return json.decode(fbRes.body) as Map<String, dynamic>;
        }
        debugPrint('Failed to load weather (${location.name}): ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching weather (${location.name}): $e');
      return null;
    }
  }

  /// Fetches 5-day / 3-hour forecast from OpenWeatherMap for a given plant location
  static Future<Map<String, dynamic>?> fetchForecast({
    WeatherLocation location = WeatherLocation.mswTanjung,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?lat=${location.lat}&lon=${location.lon}&units=metric&appid=$_apiKey',
      );
      final response = await client.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final fallbackUrl = Uri.parse(
          '$_baseUrl/forecast?q=${location.cityQuery}&units=metric&appid=$_apiKey',
        );
        final fbRes = await client.get(fallbackUrl).timeout(const Duration(seconds: 10));
        if (fbRes.statusCode == 200) {
          return json.decode(fbRes.body) as Map<String, dynamic>;
        }
        debugPrint('Failed to load forecast (${location.name}): ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching forecast (${location.name}): $e');
      return null;
    }
  }

  // ===========================================================================
  // KALKULATOR TEKNIS METEOROLOGI UNTUK SOLAR PV & OPERASIONAL PLANT
  // ===========================================================================

  /// Menghitung Indeks Potensi Solar PV (0 - 100%)
  static Map<String, dynamic> calculateSolarPvPotential({
    required int cloudPct,
    required double rainMm,
    required int hour,
  }) {
    // Night time (before 06:00 or after 18:15 WITA)
    if (hour < 6 || hour >= 19) {
      return {
        'score': 0,
        'label': 'NIGHT STANDBY',
        'sublabel': 'No solar irradiance',
        'color': const Color(0xFF94A3B8),
        'icon': Icons.nightlight_round,
      };
    }

    // Solar elevation factor (peak at 11:00 - 13:00)
    double sunElevationFactor = 1.0;
    if (hour <= 7 || hour >= 17) {
      sunElevationFactor = 0.45;
    } else if (hour <= 9 || hour >= 15) {
      sunElevationFactor = 0.78;
    } else {
      sunElevationFactor = 1.0;
    }

    // Cloud and rain penalties
    double cloudPenalty = (cloudPct / 100.0) * 0.65;
    double rainPenalty = rainMm > 0 ? (rainMm * 0.15).clamp(0.1, 0.4) : 0.0;

    double baseEfficiency = (1.0 - cloudPenalty - rainPenalty).clamp(0.1, 1.0);
    int finalScore = ((baseEfficiency * sunElevationFactor) * 100).round().clamp(0, 100);

    String label;
    String sublabel;
    Color color;
    IconData icon;

    if (finalScore >= 80) {
      label = 'HIGHLY OPTIMAL';
      sublabel = 'High irradiance, ideal for peak output';
      color = const Color(0xFF00E5A0);
      icon = Icons.wb_sunny_rounded;
    } else if (finalScore >= 55) {
      label = 'MODERATELY OPTIMAL';
      sublabel = 'Partly cloudy, stable output';
      color = const Color(0xFFFFB020);
      icon = Icons.wb_cloudy_rounded;
    } else if (finalScore >= 30) {
      label = 'LOW POTENTIAL';
      sublabel = 'Overcast / drizzle';
      color = const Color(0xFFFF8A00);
      icon = Icons.cloud_queue_rounded;
    } else {
      label = 'MINIMAL';
      sublabel = 'Heavy rain / dense cloud cover';
      color = const Color(0xFFFF4D6A);
      icon = Icons.thunderstorm_rounded;
    }

    return {
      'score': finalScore,
      'label': label,
      'sublabel': sublabel,
      'color': color,
      'icon': icon,
    };
  }

  /// Menghitung estimasi Solar Irradiance teoritis permukaan (W/m²)
  static double estimateSolarIrradiance({
    required int cloudPct,
    required int hour,
    double rainMm = 0.0,
  }) {
    if (hour < 6 || hour >= 19) return 0.0;

    // Model kurva bell 06:00 - 18:30 (puncak ~980 W/m² di Kalsel khatulistiwa)
    final normTime = (hour - 6.0) / 12.5;
    final clearSkyWatts = (sin(normTime * pi).clamp(0.0, 1.0) * 980.0);

    // Redaman radiasi akibat tutupan awan & presipitasi
    final cloudTransmission = (1.0 - (cloudPct / 100.0) * 0.72).clamp(0.12, 1.0);
    final rainFactor = rainMm > 0 ? 0.7 : 1.0;

    final result = clearSkyWatts * cloudTransmission * rainFactor;
    return double.parse(result.toStringAsFixed(1));
  }

  /// Estimasi UV Index (0 - 12+)
  static double estimateUvIndex({
    required int hour,
    required int cloudPct,
  }) {
    if (hour < 7 || hour >= 18) return 0.0;
    final normTime = (hour - 7.0) / 10.0;
    final peakUv = sin(normTime * pi).clamp(0.0, 1.0) * 11.5;
    final uv = peakUv * (1.0 - (cloudPct / 100.0) * 0.5);
    return double.parse(uv.toStringAsFixed(1));
  }

  /// Evaluates operational wind risk for barges and jetty at Kelanis Port
  static Map<String, dynamic> calculateJettyWindRisk({
    required double windSpeedMs,
    double? gustMs,
  }) {
    final effectiveWind = max(windSpeedMs, (gustMs ?? 0.0) * 0.85);

    if (effectiveWind < 6.5) {
      return {
        'level': PlantRiskLevel.safe,
        'title': 'Safe Berthing Operations',
        'detail': 'Low wind speed (${windSpeedMs.toStringAsFixed(1)} m/s), safe for 300ft barges.',
      };
    } else if (effectiveWind <= 11.0) {
      return {
        'level': PlantRiskLevel.caution,
        'title': 'Caution: Wind & Currents',
        'detail': 'Gusts reaching ${(gustMs ?? windSpeedMs).toStringAsFixed(1)} m/s. Ensure double mooring lines.',
      };
    } else {
      return {
        'level': PlantRiskLevel.warning,
        'title': 'High Wind Warning',
        'detail': 'Wind > 11 m/s. Postponing barge berthing/unmooring recommended for jetty safety.',
      };
    }
  }

  /// Evaluates moisture risk on coal stockpile
  static Map<String, dynamic> calculateStockpileMoistureRisk({
    required int humidityPct,
    required double rainMm,
  }) {
    if (rainMm >= 5.0) {
      return {
        'level': PlantRiskLevel.warning,
        'title': 'High Precipitation',
        'detail': 'Heavy rain (${rainMm.toStringAsFixed(1)} mm). Significant risk of coal Total Moisture (TM) increase.',
      };
    } else if (rainMm > 0.0 || humidityPct >= 85) {
      return {
        'level': PlantRiskLevel.caution,
        'title': 'High Humidity',
        'detail': 'RH $humidityPct% with drizzle. Monitor potential wet coal clogging on chute feeder.',
      };
    } else {
      return {
        'level': PlantRiskLevel.safe,
        'title': 'Dry Coal Condition',
        'detail': 'No rain (RH $humidityPct%). Optimal coal transfer flow.',
      };
    }
  }

  /// Evaluates thermal derating risk on PLTS solar inverter shelter
  static Map<String, dynamic> calculateThermalDeratingRisk({
    required double tempC,
    required int humidityPct,
  }) {
    if (tempC >= 36.0) {
      return {
        'level': PlantRiskLevel.warning,
        'title': 'Extreme Temperature (> 36°C)',
        'detail': 'Risk of inverter internal power derating. Ensure shelter exhaust fan is fully running.',
      };
    } else if (tempC >= 32.5) {
      return {
        'level': PlantRiskLevel.caution,
        'title': 'Elevated Temperature (32 - 36°C)',
        'detail': 'Inverter operating at elevated temperature. Monitor IGBT temperature via Inverter Detail page.',
      };
    } else {
      return {
        'level': PlantRiskLevel.safe,
        'title': 'Optimal Ambient Temperature',
        'detail': 'Air temperature ${tempC.toStringAsFixed(1)}°C is safe for natural convection cooling of inverters.',
      };
    }
  }
}
