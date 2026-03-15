import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/models/weather_snapshot.dart';

class OpenWeatherApiService {
  OpenWeatherApiService({
    required this.client,
    required this.apiKey,
  });

  final http.Client client;
  final String apiKey;

  Future<WeatherSnapshot> fetchTodayWeather({
    required double latitude,
    required double longitude,
  }) async {
    final currentUri = Uri.https(
      'api.openweathermap.org',
      '/data/2.5/weather',
      {
        'lat': '$latitude',
        'lon': '$longitude',
        'appid': apiKey,
        'units': 'metric',
        'lang': 'kr',
      },
    );

    final forecastUri = Uri.https(
      'api.openweathermap.org',
      '/data/2.5/forecast',
      {
        'lat': '$latitude',
        'lon': '$longitude',
        'appid': apiKey,
        'units': 'metric',
        'lang': 'kr',
        'cnt': '6',
      },
    );

    final currentResponse = await client.get(currentUri);
    if (currentResponse.statusCode < 200 || currentResponse.statusCode >= 300) {
      throw OpenWeatherException(
        'OpenWeather current weather request failed with ${currentResponse.statusCode}',
      );
    }

    final forecastResponse = await client.get(forecastUri);
    if (forecastResponse.statusCode < 200 || forecastResponse.statusCode >= 300) {
      throw OpenWeatherException(
        'OpenWeather forecast request failed with ${forecastResponse.statusCode}',
      );
    }

    final currentJson = jsonDecode(currentResponse.body) as Map<String, dynamic>;
    final forecastJson = jsonDecode(forecastResponse.body) as Map<String, dynamic>;

    final weatherList = currentJson['weather'] as List<dynamic>? ?? const [];
    final forecastList = (forecastJson['list'] as List<dynamic>? ?? const []).take(6).toList();
    final firstForecast =
        forecastList.isNotEmpty ? forecastList.first as Map<String, dynamic> : const {};

    return WeatherSnapshot(
      summary: weatherList.isNotEmpty
          ? ((weatherList.first as Map<String, dynamic>)['description']?.toString() ??
              '날씨 정보 없음')
          : '날씨 정보 없음',
      temperature: (currentJson['main'] as Map<String, dynamic>? ?? const {})['temp'] is num
          ? (((currentJson['main'] as Map<String, dynamic>)['temp'] as num).toDouble())
          : 0,
      feelsLike:
          (currentJson['main'] as Map<String, dynamic>? ?? const {})['feels_like'] is num
              ? (((currentJson['main'] as Map<String, dynamic>)['feels_like'] as num)
                  .toDouble())
              : 0,
      precipitationProbability: (firstForecast['pop'] as num?)?.toDouble() ?? 0,
      windSpeed:
          (currentJson['wind'] as Map<String, dynamic>? ?? const {})['speed'] is num
              ? (((currentJson['wind'] as Map<String, dynamic>)['speed'] as num).toDouble())
              : 0,
      hourlyForecast: forecastList
          .map(
            (entry) =>
                (((entry as Map<String, dynamic>)['main'] as Map<String, dynamic>? ??
                            const {})['temp'] as num?)
                        ?.toDouble() ??
                    0,
          )
          .toList(),
      isFallback: false,
      sourceLabel: '현재 위치 날씨',
    );
  }
}

class OpenWeatherException implements Exception {
  OpenWeatherException(this.message);

  final String message;

  @override
  String toString() => message;
}
