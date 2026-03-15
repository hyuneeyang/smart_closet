import '../../../shared/models/trend_signal.dart';
import '../domain/trend_repository.dart';
import 'remote_trend_data_source.dart';

class RemoteTrendRepositoryImpl implements TrendRepository {
  RemoteTrendRepositoryImpl(this._dataSource);

  final RemoteTrendDataSource _dataSource;

  @override
  Future<List<TrendSignal>> fetchTrendSignals() => _dataSource.fetchTrendSignals();
}
