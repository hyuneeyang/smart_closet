import 'package:flutter_test/flutter_test.dart';
import 'package:smart_closet/src/features/ai/data/mock_clothing_analysis_service.dart';
import 'package:smart_closet/src/features/closet/data/clothing_registration_repository_impl.dart';
import 'package:smart_closet/src/features/closet/domain/register_clothing_item_use_case.dart';
import 'package:smart_closet/src/shared/models/clothing_item_draft.dart';

void main() {
  test('이미지 없는 draft는 fallback 분석 결과를 반환한다', () async {
    final repository = ClothingRegistrationRepositoryImpl(
      MockClothingAnalysisService(),
    );
    final useCase = RegisterClothingItemUseCase(repository);

    final result = await useCase.analyze(
      const ClothingItemDraft(
        title: '베이지 코트',
        sourceType: 'manual',
      ),
    );

    expect(result.category, isNotEmpty);
    expect(result.styleTags, isNotEmpty);
    expect(result.confidence, greaterThanOrEqualTo(0));
  });
}
