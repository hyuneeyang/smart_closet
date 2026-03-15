import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_shell.dart';
import '../../../core/constants/app_enums.dart';
import '../../../shared/models/clothing_analysis.dart';
import '../../../shared/models/clothing_item_draft.dart';
import '../../../shared/models/clothing_item.dart';
import '../../../shared/widgets/item_image_view.dart';
import '../../recommendation/data/recommendation_controller.dart';

class ClothingItemDetailSheet extends ConsumerStatefulWidget {
  const ClothingItemDetailSheet({
    super.key,
    required this.item,
  });

  final ClothingItem item;

  @override
  ConsumerState<ClothingItemDetailSheet> createState() => _ClothingItemDetailSheetState();
}

class _ClothingItemDetailSheetState extends ConsumerState<ClothingItemDetailSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _primaryColorController;
  late final TextEditingController _subcategoryController;
  late final TextEditingController _patternController;
  late final TextEditingController _materialController;
  late final TextEditingController _styleTagsController;
  late final TextEditingController _seasonTagsController;
  late ClothingCategory _category;
  late double _warmthScore;
  late double _formalityScore;
  late bool _waterproof;
  bool _saving = false;
  String? _analysisNotice;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item.title);
    _primaryColorController = TextEditingController(text: item.primaryColor);
    _subcategoryController = TextEditingController(text: item.subcategory ?? '');
    _patternController = TextEditingController(text: item.pattern ?? '');
    _materialController = TextEditingController(text: item.material ?? '');
    _styleTagsController = TextEditingController(text: item.styleTags.join(', '));
    _seasonTagsController = TextEditingController(text: item.seasonTags.join(', '));
    _category = item.category;
    _warmthScore = item.warmthScore;
    _formalityScore = item.formalityScore;
    _waterproof = item.waterproof;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _primaryColorController.dispose();
    _subcategoryController.dispose();
    _patternController.dispose();
    _materialController.dispose();
    _styleTagsController.dispose();
    _seasonTagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final wornCount = ref
        .watch(outfitFeedbackProvider)
        .where((entry) => entry.feedbackType == 'worn')
        .length;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ItemImageView(
                imageUrl: item.imageUrl,
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text('아이템 수정', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('착용 기록 $wornCount회', style: Theme.of(context).textTheme.bodyMedium),
            if (_analysisNotice != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2DD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(_analysisNotice!),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ClothingCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: '카테고리'),
              items: ClothingCategory.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(_categoryLabel(value)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _category = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _primaryColorController,
              decoration: const InputDecoration(labelText: '대표 색상'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subcategoryController,
              decoration: const InputDecoration(labelText: '서브카테고리'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _patternController,
              decoration: const InputDecoration(labelText: '패턴'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _materialController,
              decoration: const InputDecoration(labelText: '소재'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _styleTagsController,
              decoration: const InputDecoration(labelText: '스타일 태그 (쉼표 구분)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _seasonTagsController,
              decoration: const InputDecoration(labelText: '계절 태그 (쉼표 구분)'),
            ),
            const SizedBox(height: 16),
            Text('보온성 ${_warmthScore.toStringAsFixed(2)}'),
            Slider(
              value: _warmthScore.clamp(0, 1),
              onChanged: (value) => setState(() => _warmthScore = value),
            ),
            const SizedBox(height: 8),
            Text('포멀리티 ${_formalityScore.toStringAsFixed(2)}'),
            Slider(
              value: _formalityScore.clamp(0, 1),
              onChanged: (value) => setState(() => _formalityScore = value),
            ),
            SwitchListTile(
              value: _waterproof,
              onChanged: (value) => setState(() => _waterproof = value),
              title: const Text('생활방수'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? '저장 중...' : '수정 저장'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _saving ? null : _reanalyze,
                icon: const Icon(Icons.auto_awesome),
                label: Text(_saving ? '재분석 중...' : 'AI 재분석'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _saving
                    ? null
                    : () {
                        ref.read(focusedItemProvider.notifier).state = widget.item;
                        ref.read(shellTabProvider.notifier).state = 0;
                        Navigator.of(context).pop();
                      },
                child: const Text('이 옷으로 코디 추천'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _saving ? null : _delete,
                child: const Text('삭제'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.item.copyWith(
        title: _titleController.text.trim(),
        category: _category,
        primaryColor: _primaryColorController.text.trim(),
        subcategory: _subcategoryController.text.trim(),
        pattern: _patternController.text.trim(),
        material: _materialController.text.trim(),
        styleTags: _splitTags(_styleTagsController.text),
        seasonTags: _splitTags(_seasonTagsController.text),
        warmthScore: _warmthScore,
        formalityScore: _formalityScore,
        waterproof: _waterproof,
      );

      await ref.read(closetItemUpdateProvider).updateItem(updated);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('아이템 정보를 수정했어요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _saving = true);
    try {
      await ref.read(closetItemUpdateProvider).deleteItem(widget.item);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('아이템을 삭제했어요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reanalyze() async {
    setState(() {
      _saving = true;
      _analysisNotice = null;
    });
    try {
      final useCase = ref.read(registerClothingItemUseCaseProvider);
      final imageUrl = widget.item.imageUrl;
      final sourceUrl = imageUrl.startsWith('http') || imageUrl.startsWith('data:')
          ? imageUrl
          : null;

      final analysis = await useCase.analyze(
        ClothingItemDraft(
          title: _titleController.text.trim().isEmpty ? widget.item.title : _titleController.text.trim(),
          sourceType: sourceUrl == null ? 'manual' : 'link',
          sourceUrl: sourceUrl,
          manualCategory: _category,
        ),
      );

      setState(() {
        _applyAnalysis(analysis);
        _analysisNotice = 'AI 재분석 결과를 반영했습니다. 필요하면 수정 후 저장하세요.';
      });
    } catch (error) {
      setState(() {
        _analysisNotice = 'AI 재분석에 실패했습니다: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  List<String> _splitTags(String text) {
    return text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String _categoryLabel(ClothingCategory category) {
    return switch (category) {
      ClothingCategory.top => '상의',
      ClothingCategory.bottom => '하의',
      ClothingCategory.outer => '아우터',
      ClothingCategory.shoes => '신발',
      ClothingCategory.bag => '가방',
    };
  }

  void _applyAnalysis(ClothingAnalysis analysis) {
    _category = switch (analysis.category) {
      'top' => ClothingCategory.top,
      'bottom' => ClothingCategory.bottom,
      'outer' => ClothingCategory.outer,
      'shoes' => ClothingCategory.shoes,
      'bag' => ClothingCategory.bag,
      _ => _category,
    };
    _primaryColorController.text = analysis.colors.isNotEmpty ? analysis.colors.first : '';
    _subcategoryController.text = analysis.subcategory;
    _patternController.text = analysis.pattern;
    _materialController.text = analysis.materialGuess;
    _styleTagsController.text = analysis.styleTags.join(', ');
    _seasonTagsController.text = analysis.seasonTags.join(', ');
    _warmthScore = analysis.warmthScore;
    _formalityScore = analysis.formalityScore;
    _waterproof = analysis.waterproof;
  }
}
