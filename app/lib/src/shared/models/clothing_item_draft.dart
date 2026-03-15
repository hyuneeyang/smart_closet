import '../../core/constants/app_enums.dart';
import 'clothing_analysis.dart';

class ClothingItemDraft {
  const ClothingItemDraft({
    required this.title,
    required this.sourceType,
    this.imageBytes,
    this.fileName,
    this.sourceUrl,
    this.manualCategory,
    this.analysis,
  });

  final String title;
  final String sourceType;
  final List<int>? imageBytes;
  final String? fileName;
  final String? sourceUrl;
  final ClothingCategory? manualCategory;
  final ClothingAnalysis? analysis;
}
