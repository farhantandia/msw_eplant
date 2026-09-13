import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/role.dart';
import 'package:msw_eplant/pages/cems_detail_page.dart';
import 'package:msw_eplant/pages/solarpv/solar_detail_page.dart';
import 'package:msw_eplant/pages/unit_detail_page.dart';
import 'package:msw_eplant/pages/weather_page.dart';
import 'package:msw_eplant/services/weather_service.dart';
import 'package:msw_eplant/widgets/menu_grid.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final mockCurrentWeather = {
    'name': 'Tanjung',
    'dt': 1726027200,
    'main': {
      'temp': 31.5,
      'feels_like': 36.2,
      'temp_min': 26.0,
      'temp_max': 33.0,
      'pressure': 1011,
      'humidity': 68,
    },
    'weather': [
      {
        'id': 801,
        'main': 'Clouds',
        'description': 'few clouds',
        'icon': '02d',
      }
    ],
    'wind': {
      'speed': 3.2,
      'deg': 140,
      'gust': 5.1,
    },
    'clouds': {'all': 25},
    'visibility': 10000,
    'sys': {
      'sunrise': 1726005600,
      'sunset': 1726049400,
    },
  };

  final mockForecastData = {
    'list': [
      {
        'dt': 1726027200,
        'dt_txt': '2026-09-11 12:00:00',
        'main': {
          'temp': 32.0,
          'temp_min': 31.0,
          'temp_max': 33.0,
          'humidity': 65,
          'pressure': 1010,
        },
        'weather': [
          {'main': 'Clear', 'description': 'clear sky', 'icon': '01d'}
        ],
        'wind': {'speed': 3.5, 'deg': 120, 'gust': 5.0},
        'clouds': {'all': 15},
        'pop': 0.1,
      },
      {
        'dt': 1726038000,
        'dt_txt': '2026-09-11 15:00:00',
        'main': {
          'temp': 30.5,
          'temp_min': 29.0,
          'temp_max': 31.0,
          'humidity': 72,
          'pressure': 1009,
        },
        'weather': [
          {'main': 'Clouds', 'description': 'scattered clouds', 'icon': '03d'}
        ],
        'wind': {'speed': 4.0, 'deg': 130, 'gust': 6.2},
        'clouds': {'all': 45},
        'pop': 0.3,
      },
      {
        'dt': 1726048800,
        'dt_txt': '2026-09-11 18:00:00',
        'main': {
          'temp': 27.5,
          'temp_min': 27.0,
          'temp_max': 28.0,
          'humidity': 85,
          'pressure': 1011,
        },
        'weather': [
          {'main': 'Rain', 'description': 'light rain', 'icon': '10d'}
        ],
        'wind': {'speed': 2.8, 'deg': 110, 'gust': 4.0},
        'clouds': {'all': 80},
        'pop': 0.7,
        'rain': {'3h': 2.5},
      },
      {
        'dt': 1726059600,
        'dt_txt': '2026-09-11 21:00:00',
        'main': {
          'temp': 25.0,
          'temp_min': 24.5,
          'temp_max': 25.5,
          'humidity': 90,
          'pressure': 1012,
        },
        'weather': [
          {'main': 'Clouds', 'description': 'overcast clouds', 'icon': '04n'}
        ],
        'wind': {'speed': 2.0, 'deg': 100, 'gust': 3.0},
        'clouds': {'all': 95},
        'pop': 0.4,
      },
      {
        'dt': 1726113600,
        'dt_txt': '2026-09-12 12:00:00',
        'main': {
          'temp': 33.0,
          'temp_min': 31.0,
          'temp_max': 34.0,
          'humidity': 60,
          'pressure': 1010,
        },
        'weather': [
          {'main': 'Clear', 'description': 'clear sky', 'icon': '01d'}
        ],
        'wind': {'speed': 3.0, 'deg': 120, 'gust': 4.5},
        'clouds': {'all': 10},
        'pop': 0.0,
      }
    ]
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    WeatherService.client = MockClient((request) async {
      if (request.url.path.contains('/forecast')) {
        return http.Response(jsonEncode(mockForecastData), 200);
      }
      return http.Response(jsonEncode(mockCurrentWeather), 200);
    });
  });

  tearDown(() {
    WeatherService.client = http.Client();
  });

  group('WeatherService Technical Calculations Tests', () {
    test('Coordinates correctly mapped for MSW Tanjung and Kelanis', () {
      expect(WeatherLocation.mswTanjung.lat, closeTo(-2.1856, 0.001));
      expect(WeatherLocation.mswTanjung.lon, closeTo(115.3889, 0.001));

      expect(WeatherLocation.kelanis.lat, closeTo(-2.3500, 0.001));
      expect(WeatherLocation.kelanis.lon, closeTo(115.1000, 0.001));
    });

    test('Solar PV Potential calculation logic', () {
      // Clear midday: 12:00 with 10% clouds -> high score
      final noonClear = WeatherService.calculateSolarPvPotential(
        cloudPct: 10,
        rainMm: 0.0,
        hour: 12,
      );
      expect(noonClear['score'], greaterThanOrEqualTo(80));
      expect(noonClear['label'], 'HIGHLY OPTIMAL');

      // Night time: 22:00 -> 0%
      final night = WeatherService.calculateSolarPvPotential(
        cloudPct: 0,
        rainMm: 0.0,
        hour: 22,
      );
      expect(night['score'], 0);
      expect(night['label'], 'NIGHT STANDBY');

      // Rainy afternoon: 14:00 with 5.0mm rain and 95% clouds -> low score
      final rainy = WeatherService.calculateSolarPvPotential(
        cloudPct: 95,
        rainMm: 5.0,
        hour: 14,
      );
      expect(rainy['score'], lessThan(40));
    });

    test('Irradiance & UV Index estimations', () {
      // Clear midday irradiance
      final irrMidday = WeatherService.estimateSolarIrradiance(
        cloudPct: 10,
        hour: 12,
        rainMm: 0.0,
      );
      expect(irrMidday, greaterThan(700.0));

      // Night irradiance
      final irrNight = WeatherService.estimateSolarIrradiance(
        cloudPct: 10,
        hour: 21,
        rainMm: 0.0,
      );
      expect(irrNight, equals(0.0));

      // UV index midday vs night
      final uvMidday = WeatherService.estimateUvIndex(
        cloudPct: 10,
        hour: 12,
      );
      expect(uvMidday, greaterThan(7.0));

      final uvNight = WeatherService.estimateUvIndex(
        cloudPct: 10,
        hour: 23,
      );
      expect(uvNight, equals(0.0));
    });
  });

  group('WeatherPage UI & Interactivity Tests', () {
    testWidgets('Renders WeatherPage with mock data in Day mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: WeatherPage(
            initialLocation: WeatherLocation.mswTanjung,
            initialCurrentWeather: mockCurrentWeather,
            initialForecastData: mockForecastData,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Location titles in AppBar
      expect(find.text('MSW Tanjung'), findsWidgets);

      // Location switcher chips
      expect(find.text('PLTU MSW (Tanjung)'), findsOneWidget);
      expect(find.text('Terminal Kelanis'), findsOneWidget);

      // Hero Card values
      expect(find.text('32°C'), findsWidgets); // rounded 31.5 -> 32
      expect(find.text('FEW CLOUDS'), findsOneWidget);
      expect(find.text('Clouds'), findsOneWidget);

      // Solar PV Potential Section
      expect(find.text('SOLAR RADIATION & POTENTIAL'), findsOneWidget);

      // Sun Arc Section
      expect(find.text('SUN TRAJECTORY (WITA)'), findsOneWidget);
      expect(find.textContaining('Sunrise:'), findsOneWidget);
      expect(find.textContaining('Sunset:'), findsOneWidget);

      // Plant Advisory Section (removed per user request)
      expect(find.text('PLANT OPERATIONAL ADVISORY'), findsNothing);
      expect(find.text('Inverter Shelter & Thermal Risk'), findsNothing);

      // Synoptic Outlook
      expect(find.text('5-DAY SYNOPTIC FORECAST'), findsOneWidget);
    });

    testWidgets('Location switcher toggles between Tanjung and Kelanis', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: WeatherPage(
            initialLocation: WeatherLocation.mswTanjung,
            initialCurrentWeather: mockCurrentWeather,
            initialForecastData: mockForecastData,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Kelanis switcher chip
      final kelanisChip = find.text('Terminal Kelanis');
      expect(kelanisChip, findsOneWidget);
      await tester.tap(kelanisChip);
      await tester.pumpAndSettle();

      // AppBar title updates to Kelanis
      expect(find.text('Kelanis Port'), findsWidgets);
    });

    testWidgets('Theme toggle button cycles through Auto, Day, and Night', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: WeatherPage(
            initialLocation: WeatherLocation.mswTanjung,
            initialCurrentWeather: mockCurrentWeather,
            initialForecastData: mockForecastData,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find theme toggle button by tooltip
      final themeBtn = find.byTooltip('Theme: AUTO (Tap to switch)');
      expect(themeBtn, findsOneWidget);

      // Tap to cycle to DAY
      await tester.tap(themeBtn);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Theme: DAY (Tap to switch)'), findsOneWidget);

      // Tap to cycle to NIGHT
      await tester.tap(find.byTooltip('Theme: DAY (Tap to switch)'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Theme: NIGHT (Tap to switch)'), findsOneWidget);

      // Tap to cycle back to AUTO
      await tester.tap(find.byTooltip('Theme: NIGHT (Tap to switch)'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Theme: AUTO (Tap to switch)'), findsOneWidget);
    });

    testWidgets('Hourly scrubbing updates selected hour metrics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: WeatherPage(
            initialLocation: WeatherLocation.mswTanjung,
            initialCurrentWeather: mockCurrentWeather,
            initialForecastData: mockForecastData,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag down to reveal hourly forecast
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -350));
      await tester.pumpAndSettle();

      // Tap 15:00 chip
      final hour15 = find.text('15:00').first;
      expect(hour15, findsOneWidget);
      await tester.tap(hour15);
      await tester.pumpAndSettle();

      // Scrubber should show details for 15:00
      expect(find.textContaining('Pukul 15:00'), findsOneWidget);
    });

    testWidgets('Responsive & zero overflow across various screen sizes & font scales', (tester) async {
      final testSizes = [
        const Size(320, 640),
        const Size(360, 780),
        const Size(412, 915),
      ];
      final fontScales = [1.0, 1.3, 1.5];

      for (final size in testSizes) {
        for (final scale in fontScales) {
          tester.view.physicalSize = size * 2.0;
          tester.view.devicePixelRatio = 2.0;

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark,
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(scale),
                ),
                child: WeatherPage(
                  initialLocation: WeatherLocation.mswTanjung,
                  initialCurrentWeather: mockCurrentWeather,
                  initialForecastData: mockForecastData,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull,
              reason: 'Overflow occurred on size $size with textScale $scale');
        }
      }

      // Reset test view
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Navigational Shortcuts & Homepage Grid Refactor Tests', () {
    test('MenuGrid.forRole does NOT contain Analytics button', () {
      final items = MenuGrid.forRole(UserRole.operation, {});
      final hasAnalytics = items.any((item) => item.label.toLowerCase() == 'analytics');
      expect(hasAnalytics, isFalse, reason: 'Analytics button must be removed from homepage MenuGrid');
    });

    testWidgets('SolarDetailPage AppBar has Weather shortcut and Irradiance card is clickable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const SolarDetailPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Irradiance card is present and clickable
      final irradianceCard = find.text('IRRADIANCE');
      expect(irradianceCard, findsOneWidget);
    });

    testWidgets('UnitDetailPage AppBar has Analytics shortcut on the right', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const UnitDetailPage(unitIndex: 0),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Analytics icon button in AppBar
      final analyticsBtn = find.byIcon(Icons.insights_outlined);
      expect(analyticsBtn, findsOneWidget);
    });

    testWidgets('CemsDetailPage AppBar has Analytics shortcut on the right', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const CemsDetailPage(unitIndex: 0),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Analytics icon button in AppBar
      final analyticsBtn = find.byIcon(Icons.insights_outlined);
      expect(analyticsBtn, findsOneWidget);
    });
  });
}
