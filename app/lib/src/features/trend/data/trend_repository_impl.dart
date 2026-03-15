import '../../../shared/models/trend_signal.dart';
import '../domain/trend_repository.dart';
import 'mock_trend_data_source.dart';

class TrendRepositoryImpl implements TrendRepository {
  TrendRepositoryImpl(this._dataSource);

  final MockTrendDataSource _dataSource;

  @override
  Future<List<TrendSignal>> fetchTrendSignals() => _dataSource.fetchTrendSignals();
}
