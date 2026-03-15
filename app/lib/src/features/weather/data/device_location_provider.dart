import 'package:geolocator/geolocator.dart';

import '../domain/weather_repository.dart';

class DeviceLocationProvider implements WeatherLocationProvider {
  @override
  Future<({double latitude, double longitude})> getCurrentLocation() async {
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationProviderException('위치 서비스가 비활성화되어 있습니다.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationProviderException('위치 권한이 허용되지 않았습니다.');
    }

    final position = await Geolocator.getCurrentPosition();
    return (latitude: position.latitude, longitude: position.longitude);
  }
}

class LocationProviderException implements Exception {
  const LocationProviderException(this.message);

  final String message;

  @override
  String toString() => message;
}
