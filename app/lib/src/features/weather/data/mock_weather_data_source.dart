import '../../../shared/models/weather_snapshot.dart';

class MockWeatherDataSource {
  Future<WeatherSnapshot> fetchTodayWeather() async {
    return const WeatherSnapshot(
      summary: '흐리고 바람 약간',
      temperature: 14,
      feelsLike: 13,
      precipitationProbability: 0.35,
      windSpeed: 16,
      hourlyForecast: [12, 13, 14, 15, 13, 11],
      isFallback: true,
      sourceLabel: '샘플 날씨',
    );
  }
}
