import '../../../shared/models/weather_snapshot.dart';

abstract class WeatherRepository {
  Future<WeatherSnapshot> fetchTodayWeather();
}

abstract class WeatherLocationProvider {
  Future<({double latitude, double longitude})> getCurrentLocation();
}
