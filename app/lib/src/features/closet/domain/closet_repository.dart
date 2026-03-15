import '../../../shared/models/clothing_item.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../shared/models/wear_record.dart';

abstract class ClosetRepository {
  Future<List<ClothingItem>> fetchClothingItems();
  Future<List<WearRecord>> fetchWearHistory();
  Future<UserPreferences> fetchUserPreferences();
}
