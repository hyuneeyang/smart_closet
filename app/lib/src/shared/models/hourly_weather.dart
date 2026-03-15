class HourlyWeather {
  const HourlyWeather({
    required this.timestamp,
    required this.temperature,
    required this.precipitationProbability,
    required this.windSpeed,
    required this.summary,
  });

  final DateTime timestamp;
  final double temperature;
  final double precipitationProbability;
  final double windSpeed;
  final String summary;
}
