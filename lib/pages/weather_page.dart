import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/services/weather_service.dart';

class WeatherPage extends StatefulWidget {
  final WeatherLocation initialLocation;
  final Map<String, dynamic>? initialCurrentWeather;
  final Map<String, dynamic>? initialForecastData;

  const WeatherPage({
    super.key,
    this.initialLocation = WeatherLocation.mswTanjung,
    this.initialCurrentWeather,
    this.initialForecastData,
  });

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> with SingleTickerProviderStateMixin {
  late WeatherLocation _selectedLocation;
  bool _isLoading = true;
  Map<String, dynamic>? _currentWeather;
  Map<String, dynamic>? _forecastData;
  DateTime? _lastSyncTime;

  // Theme mode: 'auto' | 'day' | 'night'
  String _themeMode = 'auto';

  // Interactive hourly scrub bar index
  int _selectedHourIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    if (widget.initialCurrentWeather != null) {
      _currentWeather = widget.initialCurrentWeather;
      _forecastData = widget.initialForecastData;
      _isLoading = false;
      _lastSyncTime = DateTime.now();
    } else {
      _loadWeatherData();
    }
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final current = await WeatherService.fetchWeather(location: _selectedLocation);
      final forecast = await WeatherService.fetchForecast(location: _selectedLocation);
      if (mounted) {
        setState(() {
          _currentWeather = current;
          _forecastData = forecast;
          _lastSyncTime = DateTime.now();
          _isLoading = false;
          _selectedHourIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isNightTime() {
    if (_themeMode == 'day') return false;
    if (_themeMode == 'night') return true;

    // 'auto' mode: check current time vs sunset & sunrise
    final now = DateTime.now();
    if (_currentWeather != null && _currentWeather!['sys'] != null) {
      final sunriseEpoch = _currentWeather!['sys']['sunrise'] as int?;
      final sunsetEpoch = _currentWeather!['sys']['sunset'] as int?;
      if (sunriseEpoch != null && sunsetEpoch != null) {
        final sunrise = DateTime.fromMillisecondsSinceEpoch(sunriseEpoch * 1000);
        final sunset = DateTime.fromMillisecondsSinceEpoch(sunsetEpoch * 1000);
        return now.isBefore(sunrise) || now.isAfter(sunset);
      }
    }
    return now.hour < 6 || now.hour >= 18;
  }

  void _cycleThemeMode() {
    setState(() {
      if (_themeMode == 'auto') {
        _themeMode = 'day';
      } else if (_themeMode == 'day') {
        _themeMode = 'night';
      } else {
        _themeMode = 'auto';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isNight = _isNightTime();

    // Palet background dinamis: Siang (Airy Sky Azure & Sunlight Amber) vs Malam (Deep Navy Charcoal & Cyan Glow)
    final bgGradient = isNight
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF080E1A),
              Color(0xFF0F1B2E),
              Color(0xFF14243B),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E5BB0),
              Color(0xFF2C74CE),
              Color(0xFF4A8FE2),
            ],
          );

    return Container(
      decoration: BoxDecoration(gradient: bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _selectedLocation.shortName,
                  style: const TextStyle(
                    fontSize: AppTheme.fs16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _selectedLocation.region,
                  style: TextStyle(
                    fontSize: AppTheme.fs11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            // Theme Mode Toggle (Auto -> Day -> Night)
            IconButton(
              tooltip: 'Theme: ${_themeMode.toUpperCase()} (Tap to switch)',
              icon: Icon(
                _themeMode == 'auto'
                    ? Icons.brightness_auto_rounded
                    : (_themeMode == 'day' ? Icons.wb_sunny_rounded : Icons.nightlight_round),
                color: _themeMode == 'auto'
                    ? const Color(0xFF38BDF8)
                    : (_themeMode == 'day' ? const Color(0xFFFFD54F) : const Color(0xFFA78BFA)),
                size: 22,
              ),
              onPressed: _cycleThemeMode,
            ),
            // Refresh Button
            IconButton(
              tooltip: 'Refresh Weather',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
              onPressed: _loadWeatherData,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          bottom: true,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                  ),
                )
              : (_currentWeather == null
                  ? _buildErrorState()
                  : RefreshIndicator(
                      onRefresh: _loadWeatherData,
                      color: const Color(0xFF38BDF8),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Plant Location Switcher
                            _buildLocationSwitcher(isNight),

                            const SizedBox(height: 12),

                            // 2. Hero Weather & Solar Generation Condition Card
                            _buildHeroWeatherCard(isNight),

                            const SizedBox(height: 14),

                            // 3. Solar PV Potential Gauge & Radiation Metrics
                            _buildSolarPvPotentialSection(isNight),

                            const SizedBox(height: 14),

                            // 4. Sun & Moon Trajectory Arc
                            _buildSunTrajectoryCard(isNight),

                            const SizedBox(height: 14),

                            // 5. Interactive Hourly Forecast Scrubbing
                            _buildInteractiveHourlyForecast(isNight),

                            const SizedBox(height: 14),

                            // 6. 5-Day Synoptic Weather Outlook
                            _buildDailyForecast(isNight),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    )),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. PLANT LOCATION SWITCHER CHIPS
  // ===========================================================================
  Widget _buildLocationSwitcher(bool isNight) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isNight
            ? Colors.black.withValues(alpha: 0.45)
            : Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: isNight ? 0.12 : 0.25),
        ),
      ),
      child: Row(
        children: WeatherLocation.values.map((loc) {
          final isSelected = loc == _selectedLocation;
          return Expanded(
            child: InkWell(
              onTap: () {
                if (_selectedLocation != loc) {
                  setState(() {
                    _selectedLocation = loc;
                  });
                  _loadWeatherData();
                }
              },
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isNight
                          ? const Color(0xFF38BDF8).withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.35))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isSelected
                        ? (isNight ? const Color(0xFF38BDF8) : Colors.white)
                        : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        loc.name,
                        style: TextStyle(
                          fontSize: AppTheme.fs12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        loc.plantCapacity,
                        style: TextStyle(
                          fontSize: AppTheme.fs11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isNight ? const Color(0xFF00E5A0) : const Color(0xFFFFD54F))
                              : Colors.white.withValues(alpha: 0.70),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // 2. HERO WEATHER & SOLAR GENERATION CONDITION CARD
  // ===========================================================================
  Widget _buildHeroWeatherCard(bool isNight) {
    final temp = (_currentWeather!['main']['temp'] as num).toDouble();
    final feelsLike = (_currentWeather!['main']['feels_like'] as num).toDouble();
    final mainCond = _currentWeather!['weather'][0]['main']?.toString() ?? 'Clear';
    final desc = _currentWeather!['weather'][0]['description']?.toString() ?? '';
    final icon = _currentWeather!['weather'][0]['icon']?.toString() ?? '01d';
    final cloudPct = (_currentWeather!['clouds']?['all'] as num?)?.toInt() ?? 0;

    double rainMm = 0.0;
    if (_currentWeather!.containsKey('rain')) {
      if (_currentWeather!['rain'] is Map) {
        final rMap = _currentWeather!['rain'] as Map;
        rainMm = (rMap['1h'] as num?)?.toDouble() ?? (rMap['3h'] as num?)?.toDouble() ?? 0.0;
      }
    }

    final now = DateTime.now();
    final solarPvCalc = WeatherService.calculateSolarPvPotential(
      cloudPct: cloudPct,
      rainMm: rainMm,
      hour: now.hour,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNight
            ? Colors.black.withValues(alpha: 0.45)
            : Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: isNight ? 0.14 : 0.30),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isNight
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0xFF0284C7).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Location & Weather Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(now),
                      style: TextStyle(
                        fontSize: AppTheme.fs12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_lastSyncTime != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Diperbarui ${DateFormat('HH:mm').format(_lastSyncTime!)} WITA',
                        style: TextStyle(
                          fontSize: AppTheme.fs11,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            temp.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: AppTheme.fs34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '°C',
                            style: TextStyle(
                              fontSize: AppTheme.fs18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Feels like ${feelsLike.toStringAsFixed(0)}°C',
                      style: TextStyle(
                        fontSize: AppTheme.fs12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Image.network(
                'https://openweathermap.org/img/wn/$icon@4x.png',
                width: 72,
                height: 72,
                errorBuilder: (_, __, ___) => Icon(
                  isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  size: 56,
                  color: isNight ? const Color(0xFF38BDF8) : const Color(0xFFFFD54F),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Weather Condition Text
          Row(
            children: [
              Text(
                mainCond,
                style: const TextStyle(
                  fontSize: AppTheme.fs16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '•',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  desc.toUpperCase(),
                  style: TextStyle(
                    fontSize: AppTheme.fs12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.80),
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Solar PV Generation Condition Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: (solarPvCalc['color'] as Color).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (solarPvCalc['color'] as Color).withValues(alpha: 0.60),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  solarPvCalc['icon'] as IconData,
                  size: 18,
                  color: solarPvCalc['color'] as Color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOLAR PV: ${solarPvCalc['label']} (${solarPvCalc['score']}%)',
                        style: TextStyle(
                          fontSize: AppTheme.fs11,
                          fontWeight: FontWeight.w800,
                          color: solarPvCalc['color'] as Color,
                        ),
                      ),
                      Text(
                        solarPvCalc['sublabel'] as String,
                        style: TextStyle(
                          fontSize: AppTheme.fs11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.90),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. SOLAR PV POTENTIAL GAUGE & RADIATION METRICS
  // ===========================================================================
  Widget _buildSolarPvPotentialSection(bool isNight) {
    final cloudPct = (_currentWeather!['clouds']?['all'] as num?)?.toInt() ?? 0;
    final visibilityM = (_currentWeather!['visibility'] as num?)?.toDouble() ?? 10000.0;
    final now = DateTime.now();

    double rainMm = 0.0;
    if (_currentWeather!.containsKey('rain') && _currentWeather!['rain'] is Map) {
      final rMap = _currentWeather!['rain'] as Map;
      rainMm = (rMap['1h'] as num?)?.toDouble() ?? (rMap['3h'] as num?)?.toDouble() ?? 0.0;
    }

    final solarPotential = WeatherService.calculateSolarPvPotential(
      cloudPct: cloudPct,
      rainMm: rainMm,
      hour: now.hour,
    );
    final estIrr = WeatherService.estimateSolarIrradiance(
      cloudPct: cloudPct,
      hour: now.hour,
      rainMm: rainMm,
    );
    final uvIndex = WeatherService.estimateUvIndex(
      hour: now.hour,
      cloudPct: cloudPct,
    );

    final score = (solarPotential['score'] as num).toInt();
    final accentColor = solarPotential['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNight
            ? Colors.black.withValues(alpha: 0.45)
            : Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: isNight ? 0.12 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.solar_power_rounded, size: 18, color: Color(0xFFFFB020)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'SOLAR RADIATION & POTENTIAL',
                        style: TextStyle(
                          fontSize: AppTheme.fs12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$score% INDEX',
                  style: TextStyle(
                    fontSize: AppTheme.fs11,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Linear Progress Potential Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 100.0,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),

          const SizedBox(height: 12),

          // 4 Grid Telemetry Tiles
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  isNight: isNight,
                  label: 'EST. IRRADIANCE',
                  value: '$estIrr W/m²',
                  color: const Color(0xFFFFB020),
                  icon: Icons.wb_sunny_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  isNight: isNight,
                  label: 'UV INDEX',
                  value: '$uvIndex',
                  color: const Color(0xFF38BDF8),
                  icon: Icons.wb_iridescent_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  isNight: isNight,
                  label: 'CLOUD COVER',
                  value: '$cloudPct%',
                  color: const Color(0xFFA78BFA),
                  icon: Icons.cloud_queue_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  isNight: isNight,
                  label: 'VISIBILITY',
                  value: '${(visibilityM / 1000).toStringAsFixed(1)} km',
                  color: const Color(0xFF00E5A0),
                  icon: Icons.remove_red_eye_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required bool isNight,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isNight
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: isNight ? 0.08 : 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: AppTheme.fs11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: AppTheme.fs14,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. SUN & MOON TRAJECTORY ARC
  // ===========================================================================
  Widget _buildSunTrajectoryCard(bool isNight) {
    String sunriseStr = '--:--';
    String sunsetStr = '--:--';

    if (_currentWeather != null && _currentWeather!['sys'] != null) {
      final sRise = _currentWeather!['sys']['sunrise'] as int?;
      final sSet = _currentWeather!['sys']['sunset'] as int?;
      if (sRise != null) {
        sunriseStr = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(sRise * 1000));
      }
      if (sSet != null) {
        sunsetStr = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(sSet * 1000));
      }
    }

    final now = DateTime.now();
    double dayProgress = 0.0;
    if (now.hour >= 6 && now.hour <= 18) {
      dayProgress = ((now.hour - 6) + (now.minute / 60.0)) / 12.0;
      dayProgress = dayProgress.clamp(0.0, 1.0);
    } else if (now.hour > 18) {
      dayProgress = 1.0;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNight
            ? Colors.black.withValues(alpha: 0.45)
            : Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: isNight ? 0.12 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.wb_twilight_rounded, size: 18, color: Color(0xFFFFD54F)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'SUN TRAJECTORY (WITA)',
                  style: TextStyle(
                    fontSize: AppTheme.fs12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Custom visual arc
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = (constraints.maxWidth - 52).clamp(10.0, 1000.0);
              return SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Arc line
                    Positioned(
                      left: 26,
                      right: 26,
                      top: 24,
                      child: Container(
                        height: 2,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    // Progress Fill
                    Positioned(
                      left: 26,
                      width: trackWidth * dayProgress,
                      top: 24,
                      child: Container(
                        height: 2,
                        color: const Color(0xFFFFB020),
                      ),
                    ),
                    // Sunrise Icon (Left)
                    const Positioned(
                      left: 4,
                      top: 12,
                      child: Icon(Icons.wb_sunny_outlined, size: 20, color: Color(0xFFFFB020)),
                    ),
                    // Sunset Icon (Right)
                    const Positioned(
                      right: 4,
                      top: 12,
                      child: Icon(Icons.nightlight_round, size: 20, color: Color(0xFF38BDF8)),
                    ),
                    // Sun current position indicator
                    if (!isNight)
                      Positioned(
                        left: 26 + (trackWidth * dayProgress) - 12,
                        top: 13,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.wb_sunny_rounded, size: 14, color: Colors.black),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Sunrise: $sunriseStr WITA',
                  style: TextStyle(
                    fontSize: AppTheme.fs11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.90),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sunset: $sunsetStr WITA',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: AppTheme.fs11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.90),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. INTERACTIVE HOURLY FORECAST TIMELINE (TAP TO INSPECT)
  // ===========================================================================
  Widget _buildInteractiveHourlyForecast(bool isNight) {
    if (_forecastData == null) return const SizedBox.shrink();

    final list = _forecastData!['list'] as List<dynamic>? ?? [];
    final hourlyList = list.take(8).toList();
    if (hourlyList.isEmpty) return const SizedBox.shrink();

    final safeIndex = _selectedHourIndex.clamp(0, hourlyList.length - 1);
    final inspectedItem = hourlyList[safeIndex];
    final inspectedTime = DateTime.fromMillisecondsSinceEpoch(inspectedItem['dt'] * 1000);
    final inspectedTemp = (inspectedItem['main']['temp'] as num).toDouble();
    final inspectedCloud = (inspectedItem['clouds']?['all'] as num?)?.toInt() ?? 0;
    final inspectedPop = ((inspectedItem['pop'] as num?)?.toDouble() ?? 0.0) * 100.0;
    final inspectedSolar = WeatherService.calculateSolarPvPotential(
      cloudPct: inspectedCloud,
      rainMm: 0.0,
      hour: inspectedTime.hour,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNight
            ? Colors.black.withValues(alpha: 0.45)
            : Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: isNight ? 0.12 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF38BDF8)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'HOURLY FORECAST (TAP HOUR)',
                        style: TextStyle(
                          fontSize: AppTheme.fs12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Next 24h',
                style: TextStyle(
                  fontSize: AppTheme.fs11,
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Horizontal Timeline
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: hourlyList.length,
              itemBuilder: (context, index) {
                final item = hourlyList[index];
                final time = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
                final temp = (item['main']['temp'] as num).toDouble();
                final icon = item['weather'][0]['icon']?.toString() ?? '01d';
                final isSelected = index == safeIndex;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedHourIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 82,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isNight
                                ? const Color(0xFF38BDF8).withValues(alpha: 0.28)
                                : Colors.white.withValues(alpha: 0.35))
                            : (isNight
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white.withValues(alpha: 0.10)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? (isNight ? const Color(0xFF38BDF8) : Colors.white)
                              : Colors.white.withValues(alpha: isNight ? 0.08 : 0.16),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              DateFormat('HH:mm').format(time),
                              style: TextStyle(
                                fontSize: AppTheme.fs12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Image.network(
                            'https://openweathermap.org/img/wn/$icon@2x.png',
                            width: 32,
                            height: 32,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.wb_cloudy_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${temp.toStringAsFixed(0)}°C',
                              style: TextStyle(
                                fontSize: AppTheme.fs13,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? (isNight ? const Color(0xFF00E5A0) : const Color(0xFFFFD54F))
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Inspection Detail Banner for tapped hour
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isNight
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF38BDF8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pukul ${DateFormat('HH:mm').format(inspectedTime)}: ${inspectedTemp.toStringAsFixed(1)}°C · Awan $inspectedCloud% · Hujan ${inspectedPop.toStringAsFixed(0)}% · Potensi PV: ${inspectedSolar['label']}',
                    style: TextStyle(
                      fontSize: AppTheme.fs11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. 5-DAY SYNOPTIC WEATHER OUTLOOK
  // ===========================================================================
  Widget _buildDailyForecast(bool isNight) {
    if (_forecastData == null) return const SizedBox.shrink();

    final list = _forecastData!['list'] as List<dynamic>? ?? [];
    if (list.isEmpty) return const SizedBox.shrink();

    final Map<String, List<dynamic>> grouped = {};
    for (var item in list) {
      final time = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final dateStr = DateFormat('yyyy-MM-dd').format(time);
      grouped.putIfAbsent(dateStr, () => []).add(item);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final displayDays = sortedKeys.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNight
            ? Colors.black.withValues(alpha: 0.45)
            : Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: isNight ? 0.12 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF38BDF8)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '5-DAY SYNOPTIC FORECAST',
                  style: TextStyle(
                    fontSize: AppTheme.fs12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayDays.length,
            separatorBuilder: (_, __) => Divider(
              color: Colors.white.withValues(alpha: 0.08),
              height: 12,
            ),
            itemBuilder: (context, index) {
              final dateStr = displayDays[index];
              final items = grouped[dateStr]!;

              double minTemp = 999.0;
              double maxTemp = -999.0;
              String icon = '01d';
              String cond = 'Clear';

              for (var it in items) {
                final temp = (it['main']['temp'] as num).toDouble();
                if (temp < minTemp) minTemp = temp;
                if (temp > maxTemp) maxTemp = temp;

                final time = DateTime.fromMillisecondsSinceEpoch(it['dt'] * 1000);
                if (time.hour >= 11 && time.hour <= 14) {
                  icon = it['weather'][0]['icon']?.toString() ?? icon;
                  cond = it['weather'][0]['main']?.toString() ?? cond;
                }
              }

              final date = DateTime.parse(dateStr);
              final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;
              final dayLabel = isToday ? 'Today' : DateFormat('EEEE').format(date);

              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayLabel,
                          style: TextStyle(
                            fontSize: AppTheme.fs12,
                            fontWeight: FontWeight.w800,
                            color: isToday
                                ? (isNight ? const Color(0xFF38BDF8) : const Color(0xFFFFD54F))
                                : Colors.white,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM').format(date),
                          style: TextStyle(
                            fontSize: AppTheme.fs11,
                            color: Colors.white.withValues(alpha: 0.70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Image.network(
                          'https://openweathermap.org/img/wn/$icon.png',
                          width: 28,
                          height: 28,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.wb_cloudy_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            cond,
                            style: const TextStyle(
                              fontSize: AppTheme.fs11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${maxTemp.toStringAsFixed(0)}° / ${minTemp.toStringAsFixed(0)}°C',
                      style: const TextStyle(
                        fontSize: AppTheme.fs12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ERROR / OFFLINE FALLBACK STATE
  // ===========================================================================
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.white60),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Weather Data',
              style: TextStyle(
                color: Colors.white,
                fontSize: AppTheme.fs16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ensure an active internet connection to download weather telemetry for ${_selectedLocation.name}.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: AppTheme.fs12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: _loadWeatherData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

