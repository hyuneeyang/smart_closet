import '../../../shared/models/weather_snapshot.dart';
import '../domain/weather_repository.dart';
import 'openweather_api_service.dart';

class RemoteWeatherRepositoryImpl implements WeatherRepository {
  RemoteWeatherRepositoryImpl({
    required this.service,
    required this.locationProvider,
  });

  final OpenWeatherApiService service;
  final WeatherLocationProvider locationProvider;

  @override
  Future<WeatherSnapshot> fetchTodayWeather() async {
    final location = await locationProvider.getCurrentLocation();
    return service.fetchTodayWeather(
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }
}
