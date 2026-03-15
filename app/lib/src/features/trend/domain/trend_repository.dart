import '../../../shared/models/trend_signal.dart';

abstract class TrendRepository {
  Future<List<TrendSignal>> fetchTrendSignals();
}
