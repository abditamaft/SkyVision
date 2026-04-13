import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  static String get apiKey => dotenv.env['WEATHER_API_KEY'] ?? '';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Fungsi 1: Mengambil cuaca hari ini berdasarkan koordinat
  Future<Map<String, dynamic>> getCurrentWeather(double lat, double lon) async {
    // units=metric (Celcius), lang=id (Bahasa Indonesia)
    final url = Uri.parse(
      '$baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=id',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data cuaca: ${response.statusCode}');
    }
  }

  // Fungsi 2: Mengambil ramalan 5 hari ke depan (Tiap 3 Jam)
  Future<Map<String, dynamic>> getForecast(double lat, double lon) async {
    final url = Uri.parse(
      '$baseUrl/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=id',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat ramalan cuaca: ${response.statusCode}');
    }
  }
}
