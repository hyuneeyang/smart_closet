import '../../../core/constants/app_enums.dart';
import '../../../shared/models/clothing_analysis.dart';
import '../../../shared/models/clothing_item_draft.dart';
import '../../storage/domain/storage_repository.dart';
import '../../ai/domain/clothing_analysis_service.dart';
import '../domain/clothing_registration_repository.dart';
import 'supabase_closet_data_source.dart';

class ClothingRegistrationRepositoryImpl implements ClothingRegistrationRepository {
  ClothingRegistrationRepositoryImpl(
    this._analysisService, {
    this.remoteDataSource,
    this.userId,
    this.storageRepository,
  });

  final ClothingAnalysisService _analysisService;
  final SupabaseClosetDataSource? remoteDataSource;
  final String? userId;
  final StorageRepository? storageRepository;

  @override
  Future<ClothingAnalysis> analyzeDraft(ClothingItemDraft draft) async {
    if (draft.analysis != null) return draft.analysis!;

    try {
      if (draft.imageBytes != null && draft.imageBytes!.isNotEmpty) {
        return _analysisService.analyzeImage(
          imageBytes: draft.imageBytes!,
          hint: draft.title,
        );
      }

      if (draft.sourceUrl != null && draft.sourceUrl!.isNotEmpty) {
        return _analysisService.analyzeLink(
          sourceUri: Uri.parse(draft.sourceUrl!),
          titleHint: draft.title,
        );
      }

      if (draft.title.isNotEmpty) {
        return _analysisService.analyzeLink(
          sourceUri: Uri.parse('app://manual-entry'),
          titleHint: draft.title,
        );
      }
    } catch (_) {
      return _fallbackAnalysis(draft);
    }

    return _fallbackAnalysis(draft);
  }

  @override
  Future<void> saveDraft(ClothingItemDraft draft) async {
    final analysis = await analyzeDraft(draft);
    if (remoteDataSource != null && userId != null && userId!.isNotEmpty) {
      String? imageUrl;
      String? storagePath;
      if (storageRepository != null && draft.imageBytes != null && draft.imageBytes!.isNotEmpty) {
        final uploaded = await storageRepository!.uploadClothingImage(
          userId: userId!,
          bytes: draft.imageBytes!,
          fileName: draft.fileName ?? draft.title,
        );
        imageUrl = uploaded.publicUrl;
        storagePath = uploaded.path;
      }
      await remoteDataSource!.saveClothingDraft(
        userId: userId!,
        draft: draft,
        analysis: analysis,
        imageUrl: imageUrl,
        storagePath: storagePath,
      );
    }
  }

  String _fallbackCategory(ClothingCategory? category) {
    return switch (category) {
      ClothingCategory.top => 'top',
      ClothingCategory.bottom => 'bottom',
      ClothingCategory.outer => 'outer',
      ClothingCategory.shoes => 'shoes',
      ClothingCategory.bag => 'bag',
      null => '',
    };
  }

  ClothingAnalysis _fallbackAnalysis(ClothingItemDraft draft) {
    final title = draft.title.toLowerCase();
    final category = draft.manualCategory != null
        ? _fallbackCategory(draft.manualCategory)
        : _guessCategory(title);
    final colors = _guessColors(title);
    final styleTags = _guessStyleTags(title, category);
    final seasonTags = _guessSeasonTags(title);
    final waterproof = title.contains('레인') ||
        title.contains('rain') ||
        title.contains('부츠') ||
        title.contains('고어텍스') ||
        title.contains('gore-tex');
    final warmthScore = _guessWarmth(title, category);
    final formalityScore = _guessFormality(title, category);

    return ClothingAnalysis(
      category: category,
      subcategory: _guessSubcategory(title, category),
      colors: colors,
      pattern: _guessPattern(title),
      materialGuess: _guessMaterial(title),
      styleTags: styleTags,
      seasonTags: seasonTags,
      warmthScore: warmthScore,
      formalityScore: formalityScore,
      waterproof: waterproof,
      confidence: 0.42,
    );
  }

  String _guessCategory(String title) {
    if (_containsAny(title, ['코트', '자켓', '점퍼', '패딩', '가디건', '아우터', '트렌치'])) {
      return 'outer';
    }
    if (_containsAny(title, ['슬랙스', '팬츠', '청바지', '데님', '바지', '스커트', '치마'])) {
      return 'bottom';
    }
    if (_containsAny(title, ['로퍼', '부츠', '운동화', '스니커즈', '구두', '샌들'])) {
      return 'shoes';
    }
    if (_containsAny(title, ['가방', '백팩', '토트', '크로스백'])) {
      return 'bag';
    }
    return 'top';
  }

  String _guessSubcategory(String title, String category) {
    if (category == 'top' && _containsAny(title, ['니트', '셔츠', '티셔츠', '후디', '맨투맨', '블라우스'])) {
      if (title.contains('니트')) return 'knit';
      if (title.contains('셔츠')) return 'shirt';
      if (_containsAny(title, ['티셔츠', '티'])) return 'tshirt';
      if (title.contains('후디')) return 'hoodie';
      if (title.contains('맨투맨')) return 'sweatshirt';
      if (title.contains('블라우스')) return 'blouse';
    }
    if (category == 'bottom' && _containsAny(title, ['슬랙스', '청바지', '데님', '스커트', '치마', '조거'])) {
      if (title.contains('슬랙스')) return 'slacks';
      if (_containsAny(title, ['청바지', '데님'])) return 'denim';
      if (_containsAny(title, ['스커트', '치마'])) return 'skirt';
      if (title.contains('조거')) return 'jogger';
    }
    if (category == 'outer' && _containsAny(title, ['코트', '자켓', '점퍼', '패딩', '트렌치'])) {
      if (title.contains('코트')) return 'coat';
      if (title.contains('자켓')) return 'jacket';
      if (title.contains('점퍼')) return 'jumper';
      if (title.contains('패딩')) return 'padded';
      if (title.contains('트렌치')) return 'trench';
    }
    if (category == 'shoes' && _containsAny(title, ['로퍼', '부츠', '운동화', '스니커즈', '구두', '샌들'])) {
      if (title.contains('로퍼')) return 'loafer';
      if (title.contains('부츠')) return 'boots';
      if (_containsAny(title, ['운동화', '스니커즈'])) return 'sneakers';
      if (title.contains('구두')) return 'dress_shoes';
      if (title.contains('샌들')) return 'sandals';
    }
    return '';
  }

  List<String> _guessColors(String title) {
    final colors = <String>[];
    final mapping = <String, String>{
      '블랙': 'black',
      '검정': 'black',
      '화이트': 'white',
      '흰': 'white',
      '아이보리': 'ivory',
      '베이지': 'beige',
      '브라운': 'brown',
      '카멜': 'camel',
      '그레이': 'gray',
      '회색': 'gray',
      '네이비': 'navy',
      '남색': 'navy',
      '블루': 'blue',
      '파랑': 'blue',
      '카키': 'khaki',
      '올리브': 'olive',
      '그린': 'green',
      '레드': 'red',
      '와인': 'burgundy',
      '핑크': 'pink',
      '옐로': 'yellow',
      '노랑': 'yellow',
    };
    for (final entry in mapping.entries) {
      if (title.contains(entry.key.toLowerCase())) {
        colors.add(entry.value);
      }
    }
    return colors.isEmpty ? const ['unknown'] : colors.take(2).toList();
  }

  String _guessPattern(String title) {
    if (_containsAny(title, ['스트라이프', 'stripe'])) return 'striped';
    if (_containsAny(title, ['체크', 'check'])) return 'checked';
    if (_containsAny(title, ['플라워', 'flower'])) return 'floral';
    if (_containsAny(title, ['도트', 'dot'])) return 'dot';
    return 'solid';
  }

  String _guessMaterial(String title) {
    if (_containsAny(title, ['울', 'wool'])) return 'wool';
    if (_containsAny(title, ['니트', 'knit'])) return 'knit';
    if (_containsAny(title, ['데님', 'denim'])) return 'denim';
    if (_containsAny(title, ['가죽', 'leather'])) return 'leather';
    if (_containsAny(title, ['린넨', 'linen'])) return 'linen';
    if (_containsAny(title, ['코튼', 'cotton'])) return 'cotton';
    return '';
  }

  List<String> _guessStyleTags(String title, String category) {
    final tags = <String>{};
    if (_containsAny(title, ['슬랙스', '셔츠', '로퍼', '코트', '블레이저'])) {
      tags.addAll(['minimal', 'classic']);
    }
    if (_containsAny(title, ['후디', '맨투맨', '청바지', '데님'])) {
      tags.add('casual');
    }
    if (_containsAny(title, ['운동화', '러닝', '조거', '레깅스'])) {
      tags.addAll(['sporty', 'athleisure']);
    }
    if (_containsAny(title, ['트렌치', '로퍼', '니트']) && category != 'shoes') {
      tags.add('cleanfit');
    }
    if (tags.isEmpty) tags.add('casual');
    return tags.toList();
  }

  List<String> _guessSeasonTags(String title) {
    final tags = <String>{};
    if (_containsAny(title, ['패딩', '코트', '니트', '울'])) tags.addAll(['fall', 'winter']);
    if (_containsAny(title, ['린넨', '반팔', '샌들'])) tags.addAll(['spring', 'summer']);
    if (tags.isEmpty) tags.addAll(['spring', 'fall']);
    return tags.toList();
  }

  double _guessWarmth(String title, String category) {
    if (_containsAny(title, ['패딩', '헤비', '기모'])) return 0.9;
    if (_containsAny(title, ['코트', '니트', '울', '자켓'])) return 0.7;
    if (_containsAny(title, ['후디', '맨투맨', '조거'])) return 0.55;
    if (_containsAny(title, ['반팔', '샌들', '린넨'])) return 0.2;
    if (category == 'outer') return 0.6;
    return 0.4;
  }

  double _guessFormality(String title, String category) {
    if (_containsAny(title, ['정장', '블레이저', '슬랙스', '셔츠', '로퍼', '구두'])) return 0.8;
    if (_containsAny(title, ['니트', '트렌치', '코트'])) return 0.65;
    if (_containsAny(title, ['후디', '맨투맨', '운동화', '조거'])) return 0.25;
    if (category == 'shoes' && _containsAny(title, ['부츠'])) return 0.55;
    return 0.45;
  }

  bool _containsAny(String title, List<String> keywords) {
    for (final keyword in keywords) {
      if (title.contains(keyword.toLowerCase())) return true;
    }
    return false;
  }
}
