import '../../../shared/models/weather_snapshot.dart';
import '../domain/weather_repository.dart';
import 'mock_weather_data_source.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  WeatherRepositoryImpl(this._dataSource);

  final MockWeatherDataSource _dataSource;

  @override
  Future<WeatherSnapshot> fetchTodayWeather() => _dataSource.fetchTodayWeather();
}
