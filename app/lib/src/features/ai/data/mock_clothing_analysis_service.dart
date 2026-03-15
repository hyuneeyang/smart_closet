import '../../../shared/models/clothing_analysis.dart';
import '../domain/clothing_analysis_service.dart';

class MockClothingAnalysisService implements ClothingAnalysisService {
  @override
  Future<ClothingAnalysis> analyzeImage({
    required List<int> imageBytes,
    String? hint,
  }) async {
    return _fallbackAnalysis(hint);
  }

  @override
  Future<ClothingAnalysis> analyzeLink({
    required Uri sourceUri,
    String? titleHint,
  }) async {
    return _fallbackAnalysis(titleHint);
  }

  ClothingAnalysis _fallbackAnalysis(String? hint) {
    final normalized = (hint ?? '').toLowerCase();
    final isOuter = normalized.contains('코트') || normalized.contains('자켓');
    return ClothingAnalysis(
      category: isOuter ? 'outer' : 'top',
      subcategory: isOuter ? 'coat' : 'knit',
      colors: const ['beige'],
      pattern: 'solid',
      materialGuess: 'cotton',
      styleTags: const ['minimal', 'classic'],
      seasonTags: const ['spring', 'fall'],
      warmthScore: isOuter ? 0.75 : 0.55,
      formalityScore: 0.6,
      waterproof: false,
      confidence: 0.52,
    );
  }
}
