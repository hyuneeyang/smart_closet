import '../../../shared/models/clothing_analysis.dart';

abstract class ClothingAnalysisService {
  Future<ClothingAnalysis> analyzeImage({
    required List<int> imageBytes,
    String? hint,
  });

  Future<ClothingAnalysis> analyzeLink({
    required Uri sourceUri,
    String? titleHint,
  });
}
