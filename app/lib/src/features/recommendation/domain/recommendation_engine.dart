import 'dart:math';

import '../../../core/constants/app_enums.dart';
import '../../../shared/models/clothing_item.dart';
import '../../../shared/models/outfit_recommendation.dart';
import '../../../shared/models/trend_signal.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../shared/models/weather_snapshot.dart';
import '../../../shared/models/wear_record.dart';

class RecommendationEngine {
  List<OutfitRecommendation> recommend({
    required List<ClothingItem> items,
    required WeatherSnapshot weather,
    required OutfitContext context,
    required List<WearRecord> wearHistory,
    required UserPreferences preferences,
    required List<TrendSignal> trendSignals,
    ClothingItem? focusedItem,
  }) {
    final tops = _byCategory(items, ClothingCategory.top);
    final bottoms = _byCategory(items, ClothingCategory.bottom);
    final outers = _byCategory(items, ClothingCategory.outer);
    final shoes = _byCategory(items, ClothingCategory.shoes);

    final recommendations = <OutfitRecommendation>[];

    for (final top in tops) {
      for (final bottom in bottoms) {
        for (final shoe in shoes) {
          final outerCandidates = _needsOuter(weather, context)
              ? outers
              : [null, ...outers.take(1)];

          for (final outer in outerCandidates) {
            final outfitItems = <ClothingCategory, ClothingItem>{
              ClothingCategory.top: top,
              ClothingCategory.bottom: bottom,
              ClothingCategory.shoes: shoe,
              if (outer != null) ClothingCategory.outer: outer,
            };

            if (focusedItem != null &&
                !outfitItems.values.any((item) => item.id == focusedItem.id)) {
              continue;
            }

            final breakdown = _scoreOutfit(
              outfitItems,
              weather,
              context,
              wearHistory,
              preferences,
              trendSignals,
            );

            final total = _weightedTotal(breakdown).clamp(0, 1).toDouble();
            recommendations.add(
              OutfitRecommendation(
                title: _buildTitle(context),
                context: context,
                items: outfitItems,
                weather: weather,
                totalScore: total,
                breakdown: breakdown,
                reasons: _buildReasons(outfitItems, weather, context, breakdown),
              ),
            );
          }
        }
      }
    }

    recommendations.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return recommendations.take(3).toList();
  }

  List<ClothingItem> _byCategory(List<ClothingItem> items, ClothingCategory category) {
    return items.where((item) => item.category == category).toList();
  }

  bool _needsOuter(WeatherSnapshot weather, OutfitContext context) {
    return weather.isCold ||
        weather.isWindy ||
        weather.hasLargeTemperatureGap ||
        context == OutfitContext.work ||
        context == OutfitContext.formal ||
        context == OutfitContext.rainy;
  }

  ScoreBreakdown _scoreOutfit(
    Map<ClothingCategory, ClothingItem> outfit,
    WeatherSnapshot weather,
    OutfitContext context,
    List<WearRecord> wearHistory,
    UserPreferences preferences,
    List<TrendSignal> trendSignals,
  ) {
    final allItems = outfit.values.toList();
    final weatherFit = _weatherFit(allItems, weather);
    final contextFit = _contextFit(allItems, context, weather);
    final colorHarmony = _colorHarmony(allItems);
    final userPreference = _userPreferenceFit(allItems, preferences);
    final trendMatch = _trendMatch(allItems, trendSignals);
    final completeness = _closetCompleteness(outfit, weather, context);
    final recentPenalty = _recentWearPenalty(allItems, wearHistory);

    return ScoreBreakdown(
      weatherFit: weatherFit,
      contextFit: contextFit,
      colorHarmony: colorHarmony,
      userPreference: userPreference,
      trendMatch: trendMatch,
      closetCompleteness: completeness,
      recentWearPenalty: recentPenalty,
    );
  }

  double _weatherFit(List<ClothingItem> items, WeatherSnapshot weather) {
    final warmth = items.fold<double>(0, (sum, item) => sum + item.warmthScore);
    final targetWarmth = switch ((weather.feelsLike)) {
      <= 5 => 2.5,
      <= 12 => 2.0,
      <= 20 => 1.5,
      <= 27 => 1.1,
      _ => 0.8,
    };

    var score = 1 - ((warmth - targetWarmth).abs() / max(targetWarmth, 1));

    if (weather.isRainy) {
      final hasWaterproof = items.any((item) => item.waterproof);
      score += hasWaterproof ? 0.15 : -0.2;
    }
    if (weather.isWindy && items.any((item) => item.category == ClothingCategory.outer)) {
      score += 0.1;
    }
    if (weather.isHot && warmth > 1.5) {
      score -= 0.2;
    }
    return score.clamp(0, 1).toDouble();
  }

  double _contextFit(
    List<ClothingItem> items,
    OutfitContext context,
    WeatherSnapshot weather,
  ) {
    final avgFormality =
        items.fold<double>(0, (sum, item) => sum + item.formalityScore) / items.length;
    final styleTags = items.expand((item) => item.styleTags).toSet();
    final target = switch (context) {
      OutfitContext.work => (0.65, ['minimal', 'classic', 'cleanfit', 'formal']),
      OutfitContext.daily => (0.35, ['casual', 'minimal', 'cleanfit']),
      OutfitContext.date => (0.55, ['classic', 'minimal', 'oldmoney']),
      OutfitContext.travel => (0.35, ['casual', 'gorp', 'cleanfit']),
      OutfitContext.workout => (0.20, ['sporty', 'athleisure']),
      OutfitContext.gathering => (0.50, ['casual', 'classic', 'minimal']),
      OutfitContext.formal => (0.82, ['formal', 'classic']),
      OutfitContext.rainy => (0.40, ['gorp', 'casual', 'minimal']),
      OutfitContext.cold => (0.45, ['classic', 'minimal']),
      OutfitContext.hot => (0.30, ['cleanfit', 'casual']),
    };

    final formalityFit = 1 - (avgFormality - target.$1).abs();
    final styleFit = styleTags.intersection(target.$2.toSet()).length / target.$2.length;
    final rainyBoost = context == OutfitContext.rainy && weather.isRainy
        ? items.any((item) => item.waterproof) ? 0.1 : -0.1
        : 0.0;

    return (formalityFit * 0.55 + styleFit * 0.45 + rainyBoost).clamp(0, 1).toDouble();
  }

  double _colorHarmony(List<ClothingItem> items) {
    final colors = items.map((item) => item.primaryColor).toList();
    final neutrals = {'white', 'black', 'beige', 'navy', 'brown', 'camel', 'charcoal'};
    final neutralCount = colors.where(neutrals.contains).length;
    final uniqueCount = colors.toSet().length;

    double score = 0.4;
    if (neutralCount >= 2) score += 0.3;
    if (uniqueCount <= 3) score += 0.2;
    if (colors.contains('beige') && colors.contains('navy')) score += 0.1;
    if (colors.contains('olive') && colors.contains('brown')) score += 0.08;
    if (uniqueCount > 4) score -= 0.15;
    return score.clamp(0, 1).toDouble();
  }

  double _userPreferenceFit(List<ClothingItem> items, UserPreferences preferences) {
    final tags = items.expand((item) => item.styleTags).toSet();
    final colors = items.map((item) => item.primaryColor).toSet();
    final styleScore = tags.intersection(preferences.preferredStyleTags.toSet()).length /
        max(preferences.preferredStyleTags.length, 1);
    final colorScore = colors.intersection(preferences.preferredColors.toSet()).length /
        max(preferences.preferredColors.length, 1);
    return (styleScore * 0.7 + colorScore * 0.3).clamp(0, 1).toDouble();
  }

  double _trendMatch(List<ClothingItem> items, List<TrendSignal> signals) {
    if (signals.isEmpty) return 0;
    final signalMap = {for (final signal in signals) signal.keyword: signal.score};
    final tags = items.expand((item) => item.styleTags);
    final matched = tags.where(signalMap.containsKey).map((tag) => signalMap[tag]!).toList();
    if (matched.isEmpty) return 0.15;
    return (matched.reduce((a, b) => a + b) / matched.length).clamp(0, 1).toDouble();
  }

  double _closetCompleteness(
    Map<ClothingCategory, ClothingItem> outfit,
    WeatherSnapshot weather,
    OutfitContext context,
  ) {
    var score = 0.0;
    if (outfit.containsKey(ClothingCategory.top)) score += 0.3;
    if (outfit.containsKey(ClothingCategory.bottom)) score += 0.3;
    if (outfit.containsKey(ClothingCategory.shoes)) score += 0.2;
    if (_needsOuter(weather, context)) {
      score += outfit.containsKey(ClothingCategory.outer) ? 0.2 : 0.05;
    } else {
      score += 0.2;
    }
    return score.clamp(0, 1).toDouble();
  }

  double _recentWearPenalty(List<ClothingItem> items, List<WearRecord> history) {
    final now = DateTime.now();
    var penalty = 0.0;
    for (final item in items) {
      final records = history.where((record) => record.itemId == item.id);
      for (final record in records) {
        final diff = now.difference(record.wornAt).inDays;
        if (diff <= 3) {
          penalty += 0.18;
        } else if (diff <= 7) {
          penalty += 0.08;
        }
      }
    }
    return penalty.clamp(0, 0.6).toDouble();
  }

  double _weightedTotal(ScoreBreakdown breakdown) {
    return breakdown.weatherFit * 0.35 +
        breakdown.contextFit * 0.25 +
        breakdown.colorHarmony * 0.15 +
        breakdown.userPreference * 0.10 +
        breakdown.trendMatch * 0.10 +
        breakdown.closetCompleteness * 0.05 -
        breakdown.recentWearPenalty * 0.10;
  }

  List<String> _buildReasons(
    Map<ClothingCategory, ClothingItem> outfit,
    WeatherSnapshot weather,
    OutfitContext context,
    ScoreBreakdown breakdown,
  ) {
    final reasons = <String>[
      '체감온도 ${weather.feelsLike.toStringAsFixed(0)}도 기준으로 보온 밸런스를 맞췄어요.',
      '${context.label} 상황에 맞는 스타일 태그와 포멀리티를 우선 반영했어요.',
    ];

    if (weather.isWindy || weather.isRainy) {
      reasons.add('바람/강수 가능성을 반영해 아우터 또는 관리 쉬운 아이템에 가점을 줬어요.');
    }
    if (breakdown.trendMatch >= 0.6) {
      reasons.add('최근 트렌드 참고 신호에서 어울리는 스타일 키워드가 확인됐어요.');
    }

    return reasons.take(3).toList();
  }

  String _buildTitle(OutfitContext context) {
    return switch (context) {
      OutfitContext.work => '오늘의 출근 코디',
      OutfitContext.daily => '오늘의 데일리 코디',
      OutfitContext.date => '오늘의 데이트 코디',
      OutfitContext.travel => '오늘의 여행 코디',
      OutfitContext.workout => '오늘의 운동 코디',
      OutfitContext.gathering => '오늘의 모임 코디',
      OutfitContext.formal => '오늘의 포멀 코디',
      OutfitContext.rainy => '오늘의 우천 코디',
      OutfitContext.cold => '오늘의 한파 코디',
      OutfitContext.hot => '오늘의 더위 코디',
    };
  }
}
