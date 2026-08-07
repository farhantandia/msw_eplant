import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WeatherService {
  static const String _apiKey = '6ce5d5e82bf899b8eb044c9aefa7452e';
  // You can change 'Tanjung,ID' to specific lat/lon if needed
  static const String _city = 'Tanjung,ID';
  
  static Future<Map<String, dynamic>?> fetchWeather() async {
    try {
      final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$_city&units=metric&appid=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Failed to load weather: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchForecast() async {
    try {
      final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$_city&units=metric&appid=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Failed to load forecast: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching forecast: $e');
      return null;
    }
  }
}
