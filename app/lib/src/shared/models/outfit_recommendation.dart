import '../../core/constants/app_enums.dart';
import 'clothing_item.dart';
import 'weather_snapshot.dart';

class OutfitRecommendation {
  const OutfitRecommendation({
    required this.title,
    required this.context,
    required this.items,
    required this.weather,
    required this.totalScore,
    required this.breakdown,
    required this.reasons,
  });

  final String title;
  final OutfitContext context;
  final Map<ClothingCategory, ClothingItem> items;
  final WeatherSnapshot weather;
  final double totalScore;
  final ScoreBreakdown breakdown;
  final List<String> reasons;
}

class ScoreBreakdown {
  const ScoreBreakdown({
    required this.weatherFit,
    required this.contextFit,
    required this.colorHarmony,
    required this.userPreference,
    required this.trendMatch,
    required this.closetCompleteness,
    required this.recentWearPenalty,
  });

  final double weatherFit;
  final double contextFit;
  final double colorHarmony;
  final double userPreference;
  final double trendMatch;
  final double closetCompleteness;
  final double recentWearPenalty;
}
