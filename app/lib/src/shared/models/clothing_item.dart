import '../../core/constants/app_enums.dart';

class ClothingItem {
  const ClothingItem({
    required this.id,
    required this.title,
    required this.category,
    required this.primaryColor,
    required this.styleTags,
    required this.warmthScore,
    required this.formalityScore,
    required this.waterproof,
    required this.imageUrl,
    this.secondaryColor,
    this.subcategory,
    this.pattern,
    this.material,
    this.seasonTags = const [],
  });

  final String id;
  final String title;
  final ClothingCategory category;
  final String primaryColor;
  final List<String> styleTags;
  final double warmthScore;
  final double formalityScore;
  final bool waterproof;
  final String imageUrl;
  final String? secondaryColor;
  final String? subcategory;
  final String? pattern;
  final String? material;
  final List<String> seasonTags;

  ClothingItem copyWith({
    String? id,
    String? title,
    ClothingCategory? category,
    String? primaryColor,
    List<String>? styleTags,
    double? warmthScore,
    double? formalityScore,
    bool? waterproof,
    String? imageUrl,
    String? secondaryColor,
    String? subcategory,
    String? pattern,
    String? material,
    List<String>? seasonTags,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      primaryColor: primaryColor ?? this.primaryColor,
      styleTags: styleTags ?? this.styleTags,
      warmthScore: warmthScore ?? this.warmthScore,
      formalityScore: formalityScore ?? this.formalityScore,
      waterproof: waterproof ?? this.waterproof,
      imageUrl: imageUrl ?? this.imageUrl,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      subcategory: subcategory ?? this.subcategory,
      pattern: pattern ?? this.pattern,
      material: material ?? this.material,
      seasonTags: seasonTags ?? this.seasonTags,
    );
  }

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: ClothingCategory.values.firstWhere(
        (value) => value.name == json['category']?.toString(),
        orElse: () => ClothingCategory.top,
      ),
      primaryColor: json['primary_color']?.toString() ?? 'unknown',
      styleTags: ((json['style_tags'] as List?) ?? const [])
          .map((value) => value.toString())
          .toList(),
      warmthScore: (json['warmth_score'] as num?)?.toDouble() ?? 0,
      formalityScore: (json['formality_score'] as num?)?.toDouble() ?? 0,
      waterproof: json['waterproof'] == true,
      imageUrl: json['image_url']?.toString() ?? '',
      secondaryColor: json['secondary_color']?.toString(),
      subcategory: json['subcategory']?.toString(),
      pattern: json['pattern']?.toString(),
      material: json['material']?.toString(),
      seasonTags: ((json['season_tags'] as List?) ?? const [])
          .map((value) => value.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'primary_color': primaryColor,
      'style_tags': styleTags,
      'warmth_score': warmthScore,
      'formality_score': formalityScore,
      'waterproof': waterproof,
      'image_url': imageUrl,
      'secondary_color': secondaryColor,
      'subcategory': subcategory,
      'pattern': pattern,
      'material': material,
      'season_tags': seasonTags,
    };
  }
}
