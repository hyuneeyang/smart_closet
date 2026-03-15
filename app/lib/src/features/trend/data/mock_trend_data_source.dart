import '../../../shared/models/trend_signal.dart';

class MockTrendDataSource {
  Future<List<TrendSignal>> fetchTrendSignals() async {
    return const [
      TrendSignal(
        keyword: 'minimal',
        region: 'KR',
        score: 0.88,
        source: 'internal_dictionary',
        seasonHint: 'spring',
      ),
      TrendSignal(
        keyword: 'classic',
        region: 'KR',
        score: 0.81,
        source: 'google_trends',
        seasonHint: 'spring',
      ),
      TrendSignal(
        keyword: 'cleanfit',
        region: 'KR',
        score: 0.79,
        source: 'pinterest',
        seasonHint: 'all',
      ),
      TrendSignal(
        keyword: 'gorp',
        region: 'KR',
        score: 0.54,
        source: 'google_trends',
        seasonHint: 'spring',
      ),
    ];
  }
}
