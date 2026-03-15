import '../../../shared/models/clothing_analysis.dart';
import '../../../shared/models/clothing_item_draft.dart';

abstract class ClothingRegistrationRepository {
  Future<ClothingAnalysis> analyzeDraft(ClothingItemDraft draft);
  Future<void> saveDraft(ClothingItemDraft draft);
}
