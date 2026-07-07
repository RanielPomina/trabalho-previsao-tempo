import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  final String _apiKey = '1cf7b5f5bca961c2cf2bfde24b1b0081';

  Future<Weather?> fetchWeatherByCity(String city, {String? state}) async {
    if (_apiKey == 'YOUR_API_KEY') {
      return null;
    }

    final location = state != null && state.isNotEmpty ? '$city,$state' : city;
    final uri = Uri.https(
      'api.openweathermap.org',
      '/data/2.5/weather',
      {
        'q': location,
        'units': 'metric',
        'lang': 'pt_br',
        'appid': _apiKey,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      return null;
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return Weather.fromJson(data);
  }
}
