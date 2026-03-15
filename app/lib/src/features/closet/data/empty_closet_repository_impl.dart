import '../../../shared/models/clothing_item.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../shared/models/wear_record.dart';
import '../domain/closet_repository.dart';

class EmptyClosetRepositoryImpl implements ClosetRepository {
  @override
  Future<List<ClothingItem>> fetchClothingItems() async => const [];

  @override
  Future<UserPreferences> fetchUserPreferences() async {
    return const UserPreferences(
      preferredStyleTags: ['minimal', 'classic'],
      preferredColors: ['white', 'beige', 'navy'],
      frequentContexts: [],
    );
  }

  @override
  Future<List<WearRecord>> fetchWearHistory() async => const [];
}
