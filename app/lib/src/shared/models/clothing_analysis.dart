class ClothingAnalysis {
  const ClothingAnalysis({
    required this.category,
    required this.subcategory,
    required this.colors,
    required this.pattern,
    required this.materialGuess,
    required this.styleTags,
    required this.seasonTags,
    required this.warmthScore,
    required this.formalityScore,
    required this.waterproof,
    required this.confidence,
    this.raw = const {},
  });

  final String category;
  final String subcategory;
  final List<String> colors;
  final String pattern;
  final String materialGuess;
  final List<String> styleTags;
  final List<String> seasonTags;
  final double warmthScore;
  final double formalityScore;
  final bool waterproof;
  final double confidence;
  final Map<String, dynamic> raw;

  factory ClothingAnalysis.fromJson(Map<String, dynamic> json) {
    List<String> stringList(Object? value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return const [];
    }

    return ClothingAnalysis(
      category: json['category']?.toString() ?? '',
      subcategory: json['subcategory']?.toString() ?? '',
      colors: stringList(json['colors']),
      pattern: json['pattern']?.toString() ?? '',
      materialGuess: json['material_guess']?.toString() ?? '',
      styleTags: stringList(json['style_tags']),
      seasonTags: stringList(json['season_tags']),
      warmthScore: (json['warmth_score'] as num?)?.toDouble() ?? 0,
      formalityScore: (json['formality_score'] as num?)?.toDouble() ?? 0,
      waterproof: json['waterproof'] == true,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      raw: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'subcategory': subcategory,
      'colors': colors,
      'pattern': pattern,
      'material_guess': materialGuess,
      'style_tags': styleTags,
      'season_tags': seasonTags,
      'warmth_score': warmthScore,
      'formality_score': formalityScore,
      'waterproof': waterproof,
      'confidence': confidence,
    };
  }
}
