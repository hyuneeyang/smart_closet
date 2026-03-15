import 'package:flutter/material.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../shared/models/clothing_item.dart';
import '../../../../shared/models/outfit_recommendation.dart';
import '../../../../shared/widgets/item_image_view.dart';

class OutfitCard extends StatelessWidget {
  const OutfitCard({
    super.key,
    required this.recommendation,
    this.onTapBreakdown,
  });

  final OutfitRecommendation recommendation;
  final VoidCallback? onTapBreakdown;

  @override
  Widget build(BuildContext context) {
    final weather = recommendation.weather;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _InfoBadge(label: '${weather.feelsLike.toStringAsFixed(0)}° / ${weather.summary}'),
                const SizedBox(width: 8),
                _InfoBadge(label: weather.sourceLabel),
                const SizedBox(width: 8),
                _InfoBadge(label: recommendation.context.label),
                const Spacer(),
                Text(
                  '${(recommendation.totalScore * 100).round()}점',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              recommendation.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EFE7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _ItemSlot(item: recommendation.items[ClothingCategory.top])),
                      const SizedBox(width: 10),
                      Expanded(child: _ItemSlot(item: recommendation.items[ClothingCategory.outer])),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _ItemSlot(item: recommendation.items[ClothingCategory.bottom])),
                      const SizedBox(width: 10),
                      Expanded(child: _ItemSlot(item: recommendation.items[ClothingCategory.shoes])),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...recommendation.reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(reason),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onTapBreakdown,
                child: const Text('점수 상세 보기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemSlot extends StatelessWidget {
  const _ItemSlot({required this.item});

  final ClothingItem? item;

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return Container(
        height: 152,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4DCCE)),
        ),
        child: const Center(child: Text('선택 안 됨')),
      );
    }
    final resolvedItem = item!;

    return Container(
      height: 152,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ItemImageView(
              imageUrl: resolvedItem.imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
              child: Text(
              resolvedItem.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}
