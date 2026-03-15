import '../../../shared/models/trend_signal.dart';
import '../domain/trend_repository.dart';

class FallbackTrendRepositoryImpl implements TrendRepository {
  FallbackTrendRepositoryImpl({
    required this.primary,
    required this.fallback,
  });

  final TrendRepository primary;
  final TrendRepository fallback;

  @override
  Future<List<TrendSignal>> fetchTrendSignals() async {
    try {
      final result = await primary.fetchTrendSignals();
      return result.isEmpty ? await fallback.fetchTrendSignals() : result;
    } catch (_) {
      return await fallback.fetchTrendSignals();
    }
  }
}
