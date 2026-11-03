import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3674B5),
        ),
        scaffoldBackgroundColor: const Color(0xFFD1F8EF),
      ),
      home: const WeatherPage(),
    );
  }
}

// This class requests weather data from OpenWeatherMap.
class WeatherService {
  Future<Map<String, dynamic>> fetchWeather(String city) async {
    final apiKey = dotenv.env['API_KEY'];

    final response = await http.get(
      Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric',
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _cityController = TextEditingController();
  final WeatherService _weatherService = WeatherService();

  Map<String, dynamic>? _weather;
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _searchWeather() async {
    final city = _cityController.text.trim();

    if (city.isEmpty) {
      setState(() {
        _weather = null;
        _errorMessage = 'Please enter a city name.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _weather = null;
      _errorMessage = null;
    });

    try {
      final result = await _weatherService.fetchWeather(city);

      if (!mounted) return;

      setState(() {
        _weather = result;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weather = _weather;
    final temperature = weather?['main']?['temp'];
    final condition = weather?['weather']?[0]?['description'];
    final iconCode = weather?['weather']?[0]?['icon'];
    final cityName = weather?['name'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF3674B5),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Check the weather',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3674B5),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter a city to see its current weather.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF3674B5)),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _cityController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchWeather(),
                decoration: InputDecoration(
                  labelText: 'City name',
                  hintText: 'For example, Long Beach',
                  prefixIcon: const Icon(Icons.location_city),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: _isLoading ? null : _searchWeather,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF578FCA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Search',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3674B5),
                  ),
                ),

              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),

              if (weather != null)
                Card(
                  color: const Color(0xFFA1E3F9),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          cityName?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3674B5),
                          ),
                        ),
                        if (iconCode != null)
                          Image.network(
                            'https://openweathermap.org/img/wn/$iconCode@2x.png',
                            width: 100,
                            height: 100,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.cloud,
                                size: 80,
                                color: Color(0xFF3674B5),
                              );
                            },
                          ),
                        Text(
                          '${(temperature as num).round()}°C',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3674B5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          condition?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF3674B5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}