import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_enums.dart';
import '../../../shared/models/clothing_analysis.dart';
import '../../../shared/models/clothing_item.dart';
import '../../../shared/models/clothing_item_draft.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../shared/models/wear_record.dart';

class SupabaseClosetDataSource {
  SupabaseClosetDataSource(this._client);

  final SupabaseClient _client;

  Future<List<ClothingItem>> fetchClothingItems({
    required String userId,
  }) async {
    final rows = await _client
        .from('clothing_items')
        .select('*, clothing_images(storage_path)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final items = <ClothingItem>[];
    for (final row in rows as List<dynamic>) {
      items.add(await _mapClothingItem(row as Map<String, dynamic>));
    }
    return items;
  }

  Future<void> saveClothingDraft({
    required String userId,
    required ClothingItemDraft draft,
    required ClothingAnalysis analysis,
    String? imageUrl,
    String? storagePath,
  }) async {
    final inserted = await _client
        .from('clothing_items')
        .insert({
      'user_id': userId,
      'source_type': draft.sourceType,
      'title': draft.title,
      'category': analysis.category,
      'subcategory': analysis.subcategory,
      'primary_color': analysis.colors.isNotEmpty ? analysis.colors.first : null,
      'secondary_color': analysis.colors.length > 1 ? analysis.colors[1] : null,
      'pattern': analysis.pattern,
      'material': analysis.materialGuess,
      'style_tags': analysis.styleTags,
      'season_tags': analysis.seasonTags,
      'warmth_score': analysis.warmthScore,
      'formality_score': analysis.formalityScore,
      'waterproof': analysis.waterproof,
      'image_url': imageUrl,
      'source_url': draft.sourceUrl,
      'analysis_raw_json': analysis.toJson(),
      'confidence': analysis.confidence,
    })
        .select('id')
        .single();

    if (storagePath != null && storagePath.isNotEmpty) {
      await _client.from('clothing_images').insert({
        'clothing_item_id': inserted['id'],
        'storage_path': storagePath,
      });
    }
  }

  Future<void> updateClothingItem({
    required ClothingItem item,
  }) async {
    await _client.from('clothing_items').update({
      'title': item.title,
      'category': _categoryValue(item.category),
      'subcategory': item.subcategory,
      'primary_color': item.primaryColor,
      'secondary_color': item.secondaryColor,
      'pattern': item.pattern,
      'material': item.material,
      'style_tags': item.styleTags,
      'season_tags': item.seasonTags,
      'warmth_score': item.warmthScore,
      'formality_score': item.formalityScore,
      'waterproof': item.waterproof,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', item.id);
  }

  Future<void> deleteClothingItem({
    required String itemId,
  }) async {
    await _client.from('clothing_items').delete().eq('id', itemId);
  }

  Future<List<WearRecord>> fetchWearHistory({
    required String userId,
  }) async {
    final rows = await _client
        .from('wear_history')
        .select()
        .eq('user_id', userId)
        .order('worn_date', ascending: false)
        .limit(50);

    return (rows as List<dynamic>).map((row) {
      final map = row as Map<String, dynamic>;
      return WearRecord(
        itemId: map['clothing_item_id'].toString(),
        wornAt: DateTime.parse(map['worn_date'].toString()),
        context: _parseContext(map['context']?.toString()),
      );
    }).toList();
  }

  Future<UserPreferences> fetchUserPreferences({
    required String userId,
  }) async {
    final row = await _client
        .from('user_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) {
      return const UserPreferences(
        preferredStyleTags: ['minimal', 'classic'],
        preferredColors: ['white', 'beige', 'navy'],
        frequentContexts: [],
      );
    }

    return UserPreferences(
      preferredStyleTags:
          ((row['preferred_style_tags'] as List?) ?? const []).map((e) => e.toString()).toList(),
      preferredColors:
          ((row['preferred_colors'] as List?) ?? const []).map((e) => e.toString()).toList(),
      frequentContexts: ((row['frequent_contexts'] as List?) ?? const [])
          .map((e) => _parseContext(e.toString()))
          .toList(),
    );
  }

  Future<ClothingItem> _mapClothingItem(Map<String, dynamic> row) async {
    final category = row['category']?.toString() ?? '';
    final imageUrl = await _resolveImageUrl(row);
    return ClothingItem(
      id: row['id'].toString(),
      title: row['title']?.toString() ?? '',
      category: _parseCategory(category),
      primaryColor: row['primary_color']?.toString() ?? 'unknown',
      secondaryColor: row['secondary_color']?.toString(),
      subcategory: row['subcategory']?.toString(),
      pattern: row['pattern']?.toString(),
      material: row['material']?.toString(),
      styleTags: ((row['style_tags'] as List?) ?? const []).map((e) => e.toString()).toList(),
      seasonTags: ((row['season_tags'] as List?) ?? const []).map((e) => e.toString()).toList(),
      warmthScore: (row['warmth_score'] as num?)?.toDouble() ?? 0,
      formalityScore: (row['formality_score'] as num?)?.toDouble() ?? 0,
      waterproof: row['waterproof'] == true,
      imageUrl: imageUrl,
    );
  }

  Future<String> _resolveImageUrl(Map<String, dynamic> row) async {
    final fallbackUrl = row['image_url']?.toString() ?? '';
    final images = row['clothing_images'] as List<dynamic>? ?? const [];
    if (images.isEmpty) return fallbackUrl;

    final storagePath = (images.first as Map<String, dynamic>)['storage_path']?.toString();
    if (storagePath == null || storagePath.isEmpty) return fallbackUrl;

    try {
      return await _client.storage.from('clothing-images').createSignedUrl(
            storagePath,
            60 * 60 * 24 * 7,
          );
    } catch (_) {
      return fallbackUrl;
    }
  }

  ClothingCategory _parseCategory(String value) {
    return switch (value) {
      'top' => ClothingCategory.top,
      'bottom' => ClothingCategory.bottom,
      'outer' => ClothingCategory.outer,
      'shoes' => ClothingCategory.shoes,
      'bag' => ClothingCategory.bag,
      _ => ClothingCategory.top,
    };
  }

  String _categoryValue(ClothingCategory category) {
    return switch (category) {
      ClothingCategory.top => 'top',
      ClothingCategory.bottom => 'bottom',
      ClothingCategory.outer => 'outer',
      ClothingCategory.shoes => 'shoes',
      ClothingCategory.bag => 'bag',
    };
  }

  OutfitContext _parseContext(String? value) {
    return switch (value) {
      'work' => OutfitContext.work,
      'daily' => OutfitContext.daily,
      'date' => OutfitContext.date,
      'travel' => OutfitContext.travel,
      'workout' => OutfitContext.workout,
      'gathering' => OutfitContext.gathering,
      'formal' => OutfitContext.formal,
      'rainy' => OutfitContext.rainy,
      'cold' => OutfitContext.cold,
      'hot' => OutfitContext.hot,
      _ => OutfitContext.daily,
    };
  }
}
