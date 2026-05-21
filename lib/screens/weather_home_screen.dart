import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/weather_model.dart';
import '../chat_screen.dart';

class WeatherHomeScreen extends StatefulWidget {
  const WeatherHomeScreen({super.key});

  @override
  State<WeatherHomeScreen> createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends State<WeatherHomeScreen> {
  final String _apiKey = "741a934a0c1b48f781cc1bc9962c04a4";
  final TextEditingController _controller = TextEditingController();

  WeatherData? _currentWeather;
  bool _isLoading = false;
  bool _isCelsius = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _loadLastCity();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveLastCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_city', city);
  }

  Future<void> _loadLastCity() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCity = prefs.getString('last_city');
    if (lastCity != null && lastCity.isNotEmpty) {
      setState(() {
        _controller.text = lastCity;
      });
      _fetchWeather(lastCity);
    } else {
      _fetchWeather("Manila");
    }
  }

  Future<void> _fetchWeather(String cityName) async {
    if (cityName.trim().isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final String url =
        "https://api.openweathermap.org/data/2.5/weather?q=${cityName.trim()}&units=metric&appid=$_apiKey";

    await _executeWeatherRequest(url);
  }

  Future<void> _fetchWeatherByCoordinates(double lat, double lon) async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final String url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$_apiKey";

    await _executeWeatherRequest(url);
  }

  Future<void> _executeWeatherRequest(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        setState(() {
          _currentWeather = WeatherData.fromJson(decodedData);
          _controller.text = _currentWeather!.cityName;
          _isLoading = false;
        });
        await _saveLastCity(_currentWeather!.cityName);
      } else {
        setState(() {
          _errorMessage = "Could not find weather data for this spot.";
          _isLoading = false;
          _currentWeather = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection error. Check your internet!";
        _isLoading = false;
        _currentWeather = null;
      });
    }
  }

  String _getDisplayTemperature() {
    if (_currentWeather == null) return "--";
    if (_isCelsius) {
      return "${_currentWeather!.temperatureCelsius.toStringAsFixed(1)}°C";
    } else {
      double fahrenheit = (_currentWeather!.temperatureCelsius * 9 / 5) + 32;
      return "${fahrenheit.toStringAsFixed(1)}°F";
    }
  }

  String _getDisplayWindSpeed() {
    if (_currentWeather == null) return "--";
    if (_isCelsius) {
      return "${_currentWeather!.windSpeedKmh.toStringAsFixed(1)} km/h";
    } else {
      double mph = _currentWeather!.windSpeedKmh * 0.621371;
      return "${mph.toStringAsFixed(1)} mph";
    }
  }

  Gradient _getBackgroundGradient() {
    if (_currentWeather == null) {
      return const LinearGradient(
        colors: [Colors.blueGrey, Colors.grey],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    switch (_currentWeather!.condition) {
      case WeatherCondition.sunny:
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFFE082)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case WeatherCondition.cloudy:
        return LinearGradient(
          colors: [Colors.blueGrey.shade400, Colors.blueGrey.shade100],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case WeatherCondition.rainy:
        return LinearGradient(
          colors: [Colors.grey.shade800, Colors.blueGrey.shade700],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
    }
  }

  IconData _getWeatherIcon() {
    if (_currentWeather == null) return Icons.cloud_queue;
    switch (_currentWeather!.condition) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny_rounded;
      case WeatherCondition.cloudy:
        return Icons.cloud_rounded;
      case WeatherCondition.rainy:
        return Icons.umbrella_rounded;
    }
  }

  void _openMapPicker() {
    LatLng pickedLocation = LatLng(14.5995, 120.9842); //Manila toh idol

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pinpoint Location', style: TextStyle(fontWeight: FontWeight.bold)),
          contentPadding: EdgeInsets.zero,
          insetPadding: const EdgeInsets.all(10),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: pickedLocation,
                    initialZoom: 9,
                    onTap: (tapPosition, point) {
                      setDialogState(() {
                        pickedLocation = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.bluemoonweathers',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: pickedLocation,
                          width: 45,
                          height: 45,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 15,
                  left: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: const Text(
                      'Tap anywhere to pinpoint location! Map powered by OpenFreeMap 🗺️',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600]),
              onPressed: () {
                Navigator.pop(context);
                _fetchWeatherByCoordinates(pickedLocation.latitude, pickedLocation.longitude);
              },
              child: const Text('SELECT LOCATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
                                            //67 67 67 67 67 67 67 67 67
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: _getBackgroundGradient(),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(_currentWeather != null
              ? "${_currentWeather!.cityName} Weather"
              : 'BlueMoonWeathers 🌙'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Row(
              children: [
                Text(_isCelsius ? "°C" : "°F",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: !_isCelsius,
                  onChanged: (value) {
                    setState(() {
                      _isCelsius = !value;
                    });
                  },
                ),
              ],
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.85),
                        hintText: 'Enter city...',
                        hintStyle: const TextStyle(color: Colors.black38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: const Icon(Icons.search, color: Colors.blue),
                      ),
                      onSubmitted: (value) => _fetchWeather(value),
                    ),
                  ),
                  const SizedBox(width: 10),

                  Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.map_rounded, color: Colors.blueAccent, size: 26),
                      onPressed: _openMapPicker,
                      tooltip: 'Pinpoint Location on Map',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: _isLoading ? null : () => _fetchWeather(_controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue[700],
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                )
                    : const Text('SEARCH',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 25),

              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                      child: Text(_errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold))),
                )
              else if (_currentWeather != null) ...[
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(_getWeatherIcon(),
                            size: 80,
                            color: _currentWeather!.condition == WeatherCondition.sunny
                                ? Colors.orange
                                : Colors.blue),
                        const SizedBox(height: 10),
                        Text(
                          _getDisplayTemperature(),
                          style: const TextStyle(
                              fontSize: 48, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Wind Speed: ${_getDisplayWindSpeed()}",
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  "Weather Recommendations",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 10),
                _buildRecommendationCard(),
              ]
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            String city = _currentWeather?.cityName ?? "Unknown City";
            String temp = _getDisplayTemperature();
            String condition = _currentWeather?.condition.name ?? "Cloudy";

            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: WeatherChatScreen(
                  currentCity: city,
                  currentTemperature: temp,
                  currentCondition: condition,
                ),
              ),
            );
          },
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Ask BlueMoon AI'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRecommendationCard() {
    if (_currentWeather == null) return const SizedBox.shrink();

    switch (_currentWeather!.condition) {
      case WeatherCondition.sunny:
        return Card(
          color: Colors.amber.shade50,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "☀️ Ang ganda ng gising natin ngayon! It's bright and sunny in ${_currentWeather!.cityName} with ${_getDisplayTemperature()}! Why not step outside for an adventure?",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.beach_access),
                  label: Text(
                      "Find closest destination near ${_currentWeather!.cityName}"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white),
                )
              ],
            ),
          ),
        );

      case WeatherCondition.cloudy:
        return Card(
          color: Colors.blue.shade50,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "☁️ Medyo makulimlim ngayon. The sky is looking moody over ${_currentWeather!.cityName}. Perfect time to grab a cold iced coffee or go on a casual walk around town without getting sunburned!",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        );

      case WeatherCondition.rainy:
        return Card(
          color: Colors.blueGrey.shade900,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "🌧️ Tag-ulan Vibes / Cozy Indoors",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  "Buhos ang ulan! Since it's rainy in ${_currentWeather!.cityName}, stay cozy inside! Sit back with a solid book, stream your favorite Filipino movies, or eat some hot Champorado, Sopas, or Ramen.",
                  style: const TextStyle(fontSize: 15, color: Colors.white70),
                ),
                const Divider(color: Colors.white30, height: 20),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.umbrella_rounded, color: Colors.redAccent),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Aalis ka pa rin ba? Huwag kalimutan magdala ng payong (umbrella) or raincoat to stay dry and safe!",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
    }
  }
}

// TUNG TUNG TUNG SAHUR