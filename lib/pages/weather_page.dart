import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:msw_eplant/services/weather_service.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _currentWeather;
  Map<String, dynamic>? _forecastData;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final current = await WeatherService.fetchWeather();
      final forecast = await WeatherService.fetchForecast();
      setState(() {
        _currentWeather = current;
        _forecastData = forecast;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F2027),
            const Color(0xFF203A43),
            const Color(0xFF2C5364).withOpacity(0.9),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Weather Forecast",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadWeatherData,
            )
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                ),
              )
            : (_currentWeather == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          "Failed to load weather data",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadWeatherData,
                          child: const Text("Retry"),
                        )
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadWeatherData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCurrentWeatherCard(),
                          const SizedBox(height: 20),
                          _buildStatsSection(),
                          const SizedBox(height: 24),
                          _buildHourlyForecast(),
                          const SizedBox(height: 24),
                          _buildDailyForecast(),
                        ],
                      ),
                    ),
                  )),
      ),
    );
  }

  Widget _buildCurrentWeatherCard() {
    final temp = _currentWeather!['main']['temp'].toStringAsFixed(1);
    final feelsLike = _currentWeather!['main']['feels_like'].toStringAsFixed(1);
    final desc = _currentWeather!['weather'][0]['description'];
    final mainCond = _currentWeather!['weather'][0]['main'];
    final icon = _currentWeather!['weather'][0]['icon'];
    final city = _currentWeather!['name'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              Image.network(
                'https://openweathermap.org/img/wn/$icon@4x.png',
                width: 75,
                height: 75,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.wb_sunny, size: 50, color: Colors.amber),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$temp°C",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Feels like $feelsLike°C",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    mainCond,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.cyanAccent,
                    ),
                  ),
                  Text(
                    desc.toString().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final humidity = _currentWeather!['main']['humidity'];
    final wind = _currentWeather!['wind']['speed'];

    double rainVal = 0.0;
    if (_currentWeather!.containsKey('rain')) {
      if (_currentWeather!['rain'].containsKey('1h')) {
        rainVal = double.tryParse(_currentWeather!['rain']['1h'].toString()) ?? 0.0;
      } else if (_currentWeather!['rain'].containsKey('3h')) {
        rainVal = double.tryParse(_currentWeather!['rain']['3h'].toString()) ?? 0.0;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard("Humidity", "$humidity%", Colors.blueAccent),
        _buildStatCard("Wind Speed", "${wind.toStringAsFixed(1)} m/s", Colors.tealAccent),
        _buildStatCard("Rainfall", "${rainVal.toStringAsFixed(1)} mm", Colors.lightBlueAccent),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyForecast() {
    if (_forecastData == null) return const SizedBox.shrink();

    final list = _forecastData!['list'] as List<dynamic>;
    final hourlyList = list.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Hourly Forecast (Next 24h)",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: hourlyList.length,
            itemBuilder: (context, index) {
              final item = hourlyList[index];
              final time = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
              final temp = item['main']['temp'].toStringAsFixed(1);
              final icon = item['weather'][0]['icon'];
              final pop = (item['pop'] * 100).toStringAsFixed(0);

              double rain = 0.0;
              if (item.containsKey('rain') && item['rain'].containsKey('3h')) {
                rain = double.tryParse(item['rain']['3h'].toString()) ?? 0.0;
              }

              return Container(
                width: 85,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(time),
                      style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Image.network(
                      'https://openweathermap.org/img/wn/$icon@2x.png',
                      width: 35,
                      height: 35,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.wb_sunny, size: 20, color: Colors.amber),
                    ),
                    Text(
                      "$temp°C",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      rain > 0 ? "${rain.toStringAsFixed(1)}mm" : "$pop%",
                      style: TextStyle(
                        fontSize: 14,
                        color: rain > 0 ? Colors.lightBlueAccent : Colors.grey[400],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyForecast() {
    if (_forecastData == null) return const SizedBox.shrink();

    final list = _forecastData!['list'] as List<dynamic>;

    final Map<String, List<dynamic>> grouped = {};
    for (var item in list) {
      final time = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final dateStr = DateFormat('yyyy-MM-dd').format(time);
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(item);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final displayDays = sortedKeys.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "5-Day Forecast",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayDays.length,
            separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
            itemBuilder: (context, index) {
              final dateStr = displayDays[index];
              final items = grouped[dateStr]!;

              double minTemp = 999.0;
              double maxTemp = -999.0;
              String icon = '';
              String cond = '';
              for (var it in items) {
                double temp = double.parse(it['main']['temp'].toString());
                if (temp < minTemp) minTemp = temp;
                if (temp > maxTemp) maxTemp = temp;

                final time = DateTime.fromMillisecondsSinceEpoch(it['dt'] * 1000);
                if (time.hour == 12 || icon.isEmpty) {
                  icon = it['weather'][0]['icon'];
                  cond = it['weather'][0]['main'];
                }
              }

              final date = DateTime.parse(dateStr);
              final dayName = DateFormat('EEEE').format(date);
              final dateLabel = DateFormat('dd MMM').format(date);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                          ),
                          Text(
                            dateLabel,
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          Image.network(
                            'https://openweathermap.org/img/wn/$icon.png',
                            width: 32,
                            height: 32,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.wb_cloudy, size: 20, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cond,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "${maxTemp.toStringAsFixed(0)} / ${minTemp.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
