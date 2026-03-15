import '../../../shared/models/weather_snapshot.dart';
import '../domain/weather_repository.dart';

class FallbackWeatherRepository implements WeatherRepository {
  FallbackWeatherRepository({
    required this.primary,
    required this.fallback,
  });

  final WeatherRepository primary;
  final WeatherRepository fallback;

  @override
  Future<WeatherSnapshot> fetchTodayWeather() async {
    try {
      return await primary.fetchTodayWeather();
    } catch (error) {
      final fallbackWeather = await fallback.fetchTodayWeather();
      return WeatherSnapshot(
        summary: fallbackWeather.summary,
        temperature: fallbackWeather.temperature,
        feelsLike: fallbackWeather.feelsLike,
        precipitationProbability: fallbackWeather.precipitationProbability,
        windSpeed: fallbackWeather.windSpeed,
        hourlyForecast: fallbackWeather.hourlyForecast,
        isFallback: true,
        sourceLabel: fallbackWeather.sourceLabel,
        debugReason: error.toString(),
      );
    }
  }
}
