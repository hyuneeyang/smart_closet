import '../../../shared/models/clothing_item.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../shared/models/wear_record.dart';
import '../domain/closet_repository.dart';

class FallbackClosetRepositoryImpl implements ClosetRepository {
  FallbackClosetRepositoryImpl({
    required this.primary,
    required this.fallback,
  });

  final ClosetRepository primary;
  final ClosetRepository fallback;

  @override
  Future<List<ClothingItem>> fetchClothingItems() async {
    try {
      final items = await primary.fetchClothingItems();
      return items.isEmpty ? await fallback.fetchClothingItems() : items;
    } catch (_) {
      return await fallback.fetchClothingItems();
    }
  }

  @override
  Future<UserPreferences> fetchUserPreferences() async {
    try {
      return await primary.fetchUserPreferences();
    } catch (_) {
      return await fallback.fetchUserPreferences();
    }
  }

  @override
  Future<List<WearRecord>> fetchWearHistory() async {
    try {
      return await primary.fetchWearHistory();
    } catch (_) {
      return await fallback.fetchWearHistory();
    }
  }
}
