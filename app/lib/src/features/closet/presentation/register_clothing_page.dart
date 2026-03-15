import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/models/clothing_analysis.dart';
import '../../../shared/models/clothing_item.dart';
import '../../../shared/models/clothing_item_draft.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../recommendation/data/recommendation_controller.dart';

final registrationTitleProvider = StateProvider<String>((ref) => '');
final registrationUrlProvider = StateProvider<String>((ref) => '');
final registrationCategoryProvider = StateProvider<ClothingCategory?>((ref) => null);
final analyzedDraftProvider = StateProvider<ClothingAnalysis?>((ref) => null);
final registrationStatusProvider = StateProvider<bool>((ref) => false);
final pickedImageBytesProvider = StateProvider<Uint8List?>((ref) => null);
final pickedImageNameProvider = StateProvider<String?>((ref) => null);
final analysisNoticeProvider = StateProvider<String?>((ref) => null);
final analysisUsedFallbackProvider = StateProvider<bool>((ref) => false);

const _categoryOptions = <({String value, String label})>[
  (value: 'top', label: '상의'),
  (value: 'bottom', label: '하의'),
  (value: 'outer', label: '아우터'),
  (value: 'shoes', label: '신발'),
];

const _colorOptions = <({String value, String label})>[
  (value: 'black', label: '검정'),
  (value: 'white', label: '흰색'),
  (value: 'navy', label: '네이비'),
  (value: 'beige', label: '베이지'),
  (value: 'gray', label: '회색'),
  (value: 'brown', label: '브라운'),
  (value: 'khaki', label: '카키'),
  (value: 'blue', label: '블루'),
];

const _seasonOptions = <({String value, String label})>[
  (value: 'spring', label: '봄'),
  (value: 'summer', label: '여름'),
  (value: 'fall', label: '가을'),
  (value: 'winter', label: '겨울'),
];

const _styleTagOptions = <({String value, String label})>[
  (value: 'minimal', label: '미니멀'),
  (value: 'casual', label: '캐주얼'),
  (value: 'classic', label: '클래식'),
  (value: 'cleanfit', label: '클린핏'),
  (value: 'formal', label: '포멀'),
  (value: 'sporty', label: '스포티'),
  (value: 'athleisure', label: '애슬레저'),
  (value: 'oldmoney', label: '올드머니'),
  (value: 'gorp', label: '고프코어'),
];

class RegisterClothingPage extends ConsumerWidget {
  const RegisterClothingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final title = ref.watch(registrationTitleProvider);
    final url = ref.watch(registrationUrlProvider);
    final category = ref.watch(registrationCategoryProvider);
    final analysis = ref.watch(analyzedDraftProvider);
    final isBusy = ref.watch(registrationStatusProvider);
    final pickedImage = ref.watch(pickedImageBytesProvider);
    final pickedImageName = ref.watch(pickedImageNameProvider);
    final analysisNotice = ref.watch(analysisNoticeProvider);
    final analysisUsedFallback = ref.watch(analysisUsedFallbackProvider);

    return AuthGate(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (authState.valueOrNull?.isAuthenticated == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      authState.valueOrNull?.isRemote == true
                          ? '로그인됨: ${authState.valueOrNull?.email ?? authState.valueOrNull?.userId ?? ''}'
                          : '게스트 모드: 지금 저장한 내용은 이 기기 세션에서만 유지됩니다.',
                    ),
                  ),
                  if (authState.valueOrNull?.isRemote != true)
                    TextButton(
                      onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                      child: const Text('계정 로그인으로 전환'),
                    ),
                  if (authState.valueOrNull?.isRemote == true)
                    TextButton(
                      onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                      child: const Text('로그아웃'),
                    ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: isBusy ? null : () => _pickImage(ref),
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(pickedImage == null ? '사진 선택' : '사진 변경'),
          ),
          if (pickedImage != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(
                pickedImage,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            if (pickedImageName != null) ...[
              const SizedBox(height: 8),
              Text('선택한 파일: $pickedImageName'),
            ],
          ],
          const SizedBox(height: 16),
          if (authState.valueOrNull?.isRemote == true)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F2EC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('로그인 상태입니다. 저장하면 다음 접속 때도 같은 옷장이 다시 불러와집니다.'),
            ),
          if (analysisNotice != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: analysisUsedFallback ? const Color(0xFFFFF2DD) : const Color(0xFFE8F2EC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(analysisNotice),
            ),
            if (analysisUsedFallback)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: OutlinedButton.icon(
                  onPressed: isBusy
                      ? null
                      : () => _analyzeDraft(
                            context,
                            ref,
                            ClothingItemDraft(
                              title: title,
                              sourceType: pickedImage != null
                                  ? 'upload'
                                  : (url.isNotEmpty ? 'link' : 'manual'),
                              sourceUrl: url.isNotEmpty ? url : null,
                              manualCategory: category,
                              imageBytes: pickedImage,
                              fileName: pickedImageName,
                            ),
                          ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 분석'),
                ),
              ),
          ],
          TextField(
            decoration: const InputDecoration(
              labelText: '아이템 이름',
              hintText: '예: 베이지 니트',
            ),
            onChanged: (value) => ref.read(registrationTitleProvider.notifier).state = value,
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: '웹 링크',
              hintText: '선택 입력',
            ),
            onChanged: (value) => ref.read(registrationUrlProvider.notifier).state = value,
          ),
          const SizedBox(height: 16),
          _QuickSingleSelectField<ClothingCategory>(
            label: '카테고리',
            options: const [
              (value: ClothingCategory.top, label: '상의'),
              (value: ClothingCategory.bottom, label: '하의'),
              (value: ClothingCategory.outer, label: '아우터'),
              (value: ClothingCategory.shoes, label: '신발'),
            ],
            selected: category,
            onSelected: (value) => ref.read(registrationCategoryProvider.notifier).state = value,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: isBusy
                ? null
                : () => _analyzeDraft(
                      context,
                      ref,
                      ClothingItemDraft(
                        title: title,
                        sourceType: pickedImage != null
                            ? 'upload'
                            : (url.isNotEmpty ? 'link' : 'manual'),
                        sourceUrl: url.isNotEmpty ? url : null,
                        manualCategory: category,
                        imageBytes: pickedImage,
                        fileName: pickedImageName,
                      ),
                    ),
            child: Text(isBusy ? '분석 중...' : 'AI 분석 실행'),
          ),
          const SizedBox(height: 20),
          if (analysis == null)
            const EmptyStateView(
              title: '분석 결과가 아직 없어요',
              description: '이름과 링크를 입력한 뒤 AI 분석을 실행하세요.',
            )
          else
            _AnalysisEditor(analysis: analysis),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: analysis == null || isBusy
                ? null
                : () => _saveDraft(
                      context,
                      ref,
                      ClothingItemDraft(
                        title: title,
                        sourceType: pickedImage != null
                            ? 'upload'
                            : (url.isNotEmpty ? 'link' : 'manual'),
                        sourceUrl: url.isNotEmpty ? url : null,
                        manualCategory: category,
                        imageBytes: pickedImage,
                        fileName: pickedImageName,
                        analysis: analysis,
                      ),
                    ),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeDraft(
    BuildContext context,
    WidgetRef ref,
    ClothingItemDraft draft,
  ) async {
    ref.read(registrationStatusProvider.notifier).state = true;
    ref.read(analysisNoticeProvider.notifier).state = null;
    ref.read(analysisUsedFallbackProvider.notifier).state = false;
    try {
      final result = await ref.read(registerClothingItemUseCaseProvider).analyze(draft);
      ref.read(analyzedDraftProvider.notifier).state = result;
      ref.read(analysisNoticeProvider.notifier).state = 'AI 분석 결과를 불러왔습니다.';
    } catch (error) {
      ref.read(analyzedDraftProvider.notifier).state = _fallbackAnalysis(draft);
      ref.read(analysisUsedFallbackProvider.notifier).state = true;
      ref.read(analysisNoticeProvider.notifier).state =
          'AI 분석이 일시적으로 실패해 기본 분석 결과를 표시합니다. 저장 후 나중에 다시 분석할 수 있어요.';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI 분석이 실패해 기본 분석 결과를 표시합니다: $error')),
        );
      }
    } finally {
      ref.read(registrationStatusProvider.notifier).state = false;
    }
  }

  Future<void> _saveDraft(
    BuildContext context,
    WidgetRef ref,
    ClothingItemDraft draft,
  ) async {
    ref.read(registrationStatusProvider.notifier).state = true;
    final editableAnalysis = ref.read(analyzedDraftProvider);
    try {
      ref.read(localClosetItemsProvider.notifier).addItem(
            _toClothingItem(
              editableAnalysis ?? draft.analysis!,
              draft.title,
              draft.sourceUrl,
              draft.imageBytes,
            ),
          );
      try {
        await ref.read(registerClothingItemUseCaseProvider).save(
              ClothingItemDraft(
                title: draft.title,
                sourceType: draft.sourceType,
                imageBytes: draft.imageBytes,
                fileName: draft.fileName,
                sourceUrl: draft.sourceUrl,
                manualCategory: draft.manualCategory,
                analysis: editableAnalysis ?? draft.analysis,
              ),
            );
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('원격 저장은 실패했지만 내 옷장에는 저장했어요.')),
          );
        }
      }
      ref.read(analyzedDraftProvider.notifier).state = null;
      ref.read(registrationTitleProvider.notifier).state = '';
      ref.read(registrationUrlProvider.notifier).state = '';
      ref.read(registrationCategoryProvider.notifier).state = null;
      ref.read(pickedImageBytesProvider.notifier).state = null;
      ref.read(pickedImageNameProvider.notifier).state = null;
      ref.read(analysisNoticeProvider.notifier).state = null;
      ref.read(analysisUsedFallbackProvider.notifier).state = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('아이템 저장이 완료되었습니다.')),
        );
      }
    } finally {
      ref.read(registrationStatusProvider.notifier).state = false;
    }
  }

  ClothingItem _toClothingItem(
    ClothingAnalysis analysis,
    String title,
    String? sourceUrl,
    List<int>? imageBytes,
  ) {
    final dataUrl = imageBytes != null && imageBytes.isNotEmpty
        ? 'data:image/jpeg;base64,${base64Encode(imageBytes)}'
        : null;
    return ClothingItem(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      category: _mapCategory(analysis.category),
      primaryColor: analysis.colors.isNotEmpty ? analysis.colors.first : 'unknown',
      secondaryColor: analysis.colors.length > 1 ? analysis.colors[1] : null,
      styleTags: analysis.styleTags,
      warmthScore: analysis.warmthScore,
      formalityScore: analysis.formalityScore,
      waterproof: analysis.waterproof,
      imageUrl: dataUrl ?? (sourceUrl?.isNotEmpty == true ? sourceUrl! : ''),
      subcategory: analysis.subcategory,
      pattern: analysis.pattern,
      material: analysis.materialGuess,
      seasonTags: analysis.seasonTags,
    );
  }

  ClothingCategory _mapCategory(String category) {
    return switch (category) {
      'top' => ClothingCategory.top,
      'bottom' => ClothingCategory.bottom,
      'outer' => ClothingCategory.outer,
      'shoes' => ClothingCategory.shoes,
      'bag' => ClothingCategory.bag,
      _ => ClothingCategory.top,
    };
  }

  ClothingAnalysis _fallbackAnalysis(ClothingItemDraft draft) {
    final title = draft.title.toLowerCase();
    final category = switch (draft.manualCategory) {
      ClothingCategory.top => 'top',
      ClothingCategory.bottom => 'bottom',
      ClothingCategory.outer => 'outer',
      ClothingCategory.shoes => 'shoes',
      ClothingCategory.bag => 'bag',
      null => _guessCategory(title),
    };

    return ClothingAnalysis(
      category: category,
      subcategory: _guessSubcategory(title, category),
      colors: _guessColors(title),
      pattern: 'solid',
      materialGuess: _guessMaterial(title),
      styleTags: _guessStyleTags(title),
      seasonTags: _guessSeasonTags(title),
      warmthScore: _guessWarmth(title, category),
      formalityScore: _guessFormality(title),
      waterproof: title.contains('레인') || title.contains('rain') || title.contains('부츠'),
      confidence: 0.35,
    );
  }

  String _guessCategory(String title) {
    if (_containsAny(title, ['코트', '자켓', '점퍼', '패딩', '가디건', '트렌치'])) return 'outer';
    if (_containsAny(title, ['슬랙스', '팬츠', '청바지', '데님', '바지', '스커트', '치마'])) {
      return 'bottom';
    }
    if (_containsAny(title, ['로퍼', '부츠', '운동화', '스니커즈', '구두', '샌들'])) return 'shoes';
    if (_containsAny(title, ['가방', '백팩', '토트'])) return 'bag';
    return 'top';
  }

  String _guessSubcategory(String title, String category) {
    if (category == 'top' && title.contains('셔츠')) return 'shirt';
    if (category == 'top' && title.contains('니트')) return 'knit';
    if (category == 'bottom' && title.contains('슬랙스')) return 'slacks';
    if (category == 'bottom' && _containsAny(title, ['청바지', '데님'])) return 'denim';
    if (category == 'outer' && title.contains('코트')) return 'coat';
    if (category == 'outer' && title.contains('자켓')) return 'jacket';
    if (category == 'shoes' && title.contains('로퍼')) return 'loafer';
    if (category == 'shoes' && _containsAny(title, ['운동화', '스니커즈'])) return 'sneakers';
    return '';
  }

  List<String> _guessColors(String title) {
    final colors = <String>[];
    final map = <String, String>{
      '블랙': 'black',
      '화이트': 'white',
      '하늘색': 'skyblue',
      '블루': 'blue',
      '네이비': 'navy',
      '베이지': 'beige',
      '브라운': 'brown',
      '그레이': 'gray',
      '카키': 'khaki',
      '올리브': 'olive',
    };
    for (final entry in map.entries) {
      if (title.contains(entry.key.toLowerCase())) colors.add(entry.value);
    }
    return colors.isEmpty ? const ['unknown'] : colors;
  }

  String _guessMaterial(String title) {
    if (_containsAny(title, ['울', 'wool'])) return 'wool';
    if (_containsAny(title, ['린넨', 'linen'])) return 'linen';
    if (_containsAny(title, ['데님', 'denim'])) return 'denim';
    if (_containsAny(title, ['니트', 'knit'])) return 'knit';
    if (_containsAny(title, ['코튼', 'cotton'])) return 'cotton';
    return '';
  }

  List<String> _guessStyleTags(String title) {
    final tags = <String>{};
    if (_containsAny(title, ['셔츠', '슬랙스', '로퍼', '코트'])) tags.addAll(['minimal', 'classic']);
    if (_containsAny(title, ['운동화', '조거', '후디'])) tags.addAll(['sporty', 'casual']);
    if (tags.isEmpty) tags.add('casual');
    return tags.toList();
  }

  List<String> _guessSeasonTags(String title) {
    if (_containsAny(title, ['패딩', '코트', '니트'])) return const ['fall', 'winter'];
    if (_containsAny(title, ['린넨', '반팔', '샌들'])) return const ['spring', 'summer'];
    return const ['spring', 'fall'];
  }

  double _guessWarmth(String title, String category) {
    if (_containsAny(title, ['패딩', '코트'])) return 0.85;
    if (_containsAny(title, ['니트', '자켓'])) return 0.65;
    if (_containsAny(title, ['반팔', '샌들'])) return 0.2;
    if (category == 'outer') return 0.6;
    return 0.4;
  }

  double _guessFormality(String title) {
    if (_containsAny(title, ['셔츠', '슬랙스', '로퍼', '구두'])) return 0.8;
    if (_containsAny(title, ['니트', '코트'])) return 0.65;
    if (_containsAny(title, ['운동화', '후디', '맨투맨'])) return 0.25;
    return 0.45;
  }

  bool _containsAny(String title, List<String> keywords) {
    for (final keyword in keywords) {
      if (title.contains(keyword.toLowerCase())) return true;
    }
    return false;
  }

  Future<void> _pickImage(WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1440,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    ref.read(pickedImageBytesProvider.notifier).state = bytes;
    ref.read(pickedImageNameProvider.notifier).state = image.name;
  }
}

class _AnalysisEditor extends ConsumerWidget {
  const _AnalysisEditor({required this.analysis});

  final ClothingAnalysis analysis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(analyzedDraftProvider) ?? analysis;
    final isLowConfidence = current.confidence < 0.65;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('분석 결과', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Text('신뢰도 ${(current.confidence * 100).round()}%'),
              ],
            ),
            if (isLowConfidence) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.aiLowConfidence,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            _QuickSingleSelectField<String>(
              label: '카테고리',
              options: _categoryOptions,
              selected: current.category,
              onSelected: (value) => _update(ref, current, category: value),
            ),
            _EditableField(
              label: '서브카테고리',
              value: current.subcategory,
              onChanged: (value) => _update(ref, current, subcategory: value),
            ),
            _QuickMultiSelectField(
              label: '색상',
              options: _colorOptions,
              selected: current.colors.where((color) => color != 'unknown').toList(),
              onChanged: (values) => _update(
                ref,
                current,
                colors: values.isEmpty ? ['unknown'] : values,
              ),
            ),
            _EditableField(
              label: '패턴',
              value: current.pattern,
              onChanged: (value) => _update(ref, current, pattern: value),
            ),
            _EditableField(
              label: '소재 추정',
              value: current.materialGuess,
              onChanged: (value) => _update(ref, current, materialGuess: value),
            ),
            _QuickMultiSelectField(
              label: '스타일 태그',
              options: _styleTagOptions,
              selected: current.styleTags,
              onChanged: (values) => _update(ref, current, styleTags: values),
            ),
            _QuickMultiSelectField(
              label: '계절',
              options: _seasonOptions,
              selected: current.seasonTags,
              onChanged: (values) => _update(ref, current, seasonTags: values),
            ),
          ],
        ),
      ),
    );
  }

  void _update(
    WidgetRef ref,
    ClothingAnalysis current, {
    String? category,
    String? subcategory,
    List<String>? colors,
    String? pattern,
    String? materialGuess,
    List<String>? styleTags,
    List<String>? seasonTags,
  }) {
    ref.read(analyzedDraftProvider.notifier).state = ClothingAnalysis(
          category: category ?? current.category,
          subcategory: subcategory ?? current.subcategory,
          colors: colors ?? current.colors,
          pattern: pattern ?? current.pattern,
          materialGuess: materialGuess ?? current.materialGuess,
          styleTags: styleTags ?? current.styleTags,
          seasonTags: seasonTags ?? current.seasonTags,
          warmthScore: current.warmthScore,
          formalityScore: current.formalityScore,
          waterproof: current.waterproof,
          confidence: current.confidence,
          raw: current.raw,
        );
  }
}

class _QuickSingleSelectField<T> extends StatelessWidget {
  const _QuickSingleSelectField({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<({T value, String label})> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(label),
          )),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options
                  .map(
                    (option) => ChoiceChip(
                      label: Text(option.label),
                      selected: selected == option.value,
                      onSelected: (_) => onSelected(option.value),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickMultiSelectField extends StatelessWidget {
  const _QuickMultiSelectField({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<({String value, String label})> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(label),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options
                  .map(
                    (option) => FilterChip(
                      label: Text(option.label),
                      selected: selected.contains(option.value),
                      onSelected: (isSelected) {
                        final next = [...selected];
                        if (isSelected) {
                          if (!next.contains(option.value)) {
                            next.add(option.value);
                          }
                        } else {
                          next.remove(option.value);
                        }
                        onChanged(next);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label)),
          Expanded(
            child: TextFormField(
              initialValue: value,
              onChanged: onChanged,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
