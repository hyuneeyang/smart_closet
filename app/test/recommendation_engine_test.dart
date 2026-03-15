import 'package:flutter_test/flutter_test.dart';
import 'package:smart_closet/src/core/constants/app_enums.dart';
import 'package:smart_closet/src/features/closet/data/mock_closet_data_source.dart';
import 'package:smart_closet/src/features/recommendation/domain/recommendation_engine.dart';
import 'package:smart_closet/src/features/trend/data/mock_trend_data_source.dart';
import 'package:smart_closet/src/features/weather/data/mock_weather_data_source.dart';

void main() {
  test('출근 상황에서 추천 3개를 반환한다', () async {
    final closet = MockClosetDataSource();
    final weather = MockWeatherDataSource();
    final trend = MockTrendDataSource();
    final engine = RecommendationEngine();

    final result = engine.recommend(
      items: await closet.fetchItems(),
      weather: await weather.fetchTodayWeather(),
      context: OutfitContext.work,
      wearHistory: await closet.fetchWearHistory(),
      preferences: await closet.fetchPreferences(),
      trendSignals: await trend.fetchTrendSignals(),
    );

    expect(result, hasLength(3));
    expect(result.first.totalScore, greaterThan(0.4));
    expect(result.first.items.containsKey(ClothingCategory.top), isTrue);
    expect(result.first.items.containsKey(ClothingCategory.bottom), isTrue);
    expect(result.first.items.containsKey(ClothingCategory.shoes), isTrue);
  });
}
