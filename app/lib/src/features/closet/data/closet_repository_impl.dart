import '../../../shared/models/clothing_item.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../shared/models/wear_record.dart';
import '../domain/closet_repository.dart';
import 'mock_closet_data_source.dart';

class ClosetRepositoryImpl implements ClosetRepository {
  ClosetRepositoryImpl(this._dataSource);

  final MockClosetDataSource _dataSource;

  @override
  Future<List<ClothingItem>> fetchClothingItems() => _dataSource.fetchItems();

  @override
  Future<UserPreferences> fetchUserPreferences() => _dataSource.fetchPreferences();

  @override
  Future<List<WearRecord>> fetchWearHistory() => _dataSource.fetchWearHistory();
}
