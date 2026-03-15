import '../../../shared/models/clothing_item.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../shared/models/wear_record.dart';
import '../domain/closet_repository.dart';
import 'supabase_closet_data_source.dart';

class RemoteClosetRepositoryImpl implements ClosetRepository {
  RemoteClosetRepositoryImpl({
    required this.dataSource,
    required this.userId,
  });

  final SupabaseClosetDataSource dataSource;
  final String userId;

  @override
  Future<List<ClothingItem>> fetchClothingItems() {
    return dataSource.fetchClothingItems(userId: userId);
  }

  @override
  Future<UserPreferences> fetchUserPreferences() async {
    return dataSource.fetchUserPreferences(userId: userId);
  }

  @override
  Future<List<WearRecord>> fetchWearHistory() async {
    return dataSource.fetchWearHistory(userId: userId);
  }
}
