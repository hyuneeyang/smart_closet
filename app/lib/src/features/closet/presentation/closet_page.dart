import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/models/clothing_item.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/item_image_view.dart';
import '../../recommendation/data/recommendation_controller.dart';
import 'clothing_item_detail_sheet.dart';

final closetCategoryFilterProvider = StateProvider<ClothingCategory?>((ref) => null);
final closetColorFilterProvider = StateProvider<String?>((ref) => null);

final filteredClosetItemsProvider = FutureProvider<List<ClothingItem>>((ref) async {
  final items = await ref.watch(closetItemsProvider.future);
  final category = ref.watch(closetCategoryFilterProvider);
  final color = ref.watch(closetColorFilterProvider);

  return items.where((item) {
    final categoryMatch = category == null || item.category == category;
    final colorMatch = color == null || item.primaryColor == color;
    return categoryMatch && colorMatch;
  }).toList();
});

class ClosetPage extends ConsumerWidget {
  const ClosetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(filteredClosetItemsProvider);
    final selectedCategory = ref.watch(closetCategoryFilterProvider);
    final selectedColor = ref.watch(closetColorFilterProvider);
    final auth = ref.watch(authControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (auth.valueOrNull?.isAuthenticated == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Supabase 동기화 활성화',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('전체 카테고리'),
                    selected: selectedCategory == null,
                    onSelected: (_) => ref.read(closetCategoryFilterProvider.notifier).state = null,
                  ),
                  const SizedBox(width: 8),
                  ...ClothingCategory.values.where((c) => c != ClothingCategory.bag).map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_categoryLabel(category)),
                            selected: selectedCategory == category,
                            onSelected: (_) =>
                                ref.read(closetCategoryFilterProvider.notifier).state = category,
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('전체 색상'),
                    selected: selectedColor == null,
                    onSelected: (_) => ref.read(closetColorFilterProvider.notifier).state = null,
                  ),
                  const SizedBox(width: 8),
                  ...['beige', 'white', 'navy', 'olive', 'camel', 'brown'].map(
                    (color) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(color),
                        selected: selectedColor == color,
                        onSelected: (_) =>
                            ref.read(closetColorFilterProvider.notifier).state = color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyStateView(
                    title: '옷장이 비어 있어요',
                    description: AppStrings.emptyCloset,
                  );
                }
                return GridView.builder(
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GestureDetector(
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => ClothingItemDetailSheet(item: item),
                      ),
                      child: Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                                child: ItemImageView(
                                  imageUrl: item.imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text('${_categoryLabel(item.category)} · ${item.primaryColor}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('옷장을 불러오지 못했습니다: $error')),
            ),
          ),
        ],
      ),
    );
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
}
