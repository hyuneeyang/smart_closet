import '../../../shared/models/clothing_analysis.dart';
import '../../../shared/models/clothing_item_draft.dart';
import 'clothing_registration_repository.dart';

class RegisterClothingItemUseCase {
  RegisterClothingItemUseCase(this._repository);

  final ClothingRegistrationRepository _repository;

  Future<ClothingAnalysis> analyze(ClothingItemDraft draft) {
    return _repository.analyzeDraft(draft);
  }

  Future<void> save(ClothingItemDraft draft) {
    return _repository.saveDraft(draft);
  }
}
