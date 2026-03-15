class WeatherSnapshot {
  const WeatherSnapshot({
    required this.summary,
    required this.temperature,
    required this.feelsLike,
    required this.precipitationProbability,
    required this.windSpeed,
    required this.hourlyForecast,
    this.isFallback = false,
    this.sourceLabel = '날씨',
    this.debugReason,
  });

  final String summary;
  final double temperature;
  final double feelsLike;
  final double precipitationProbability;
  final double windSpeed;
  final List<double> hourlyForecast;
  final bool isFallback;
  final String sourceLabel;
  final String? debugReason;

  bool get isRainy => precipitationProbability >= 0.45;
  bool get isWindy => windSpeed >= 18;
  bool get isCold => feelsLike <= 10;
  bool get isHot => feelsLike >= 27;
  bool get hasLargeTemperatureGap {
    if (hourlyForecast.isEmpty) return false;
    final min = hourlyForecast.reduce((a, b) => a < b ? a : b);
    final max = hourlyForecast.reduce((a, b) => a > b ? a : b);
    return (max - min) >= 8;
  }
}
