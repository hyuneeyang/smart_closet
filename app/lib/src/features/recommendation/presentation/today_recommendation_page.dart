import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_shell.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/models/clothing_item.dart';
import '../../../shared/widgets/app_chip_selector.dart';
import '../data/recommendation_controller.dart';
import 'widgets/outfit_card.dart';
import 'widgets/score_breakdown_sheet.dart';

class TodayRecommendationPage extends ConsumerWidget {
  const TodayRecommendationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedContext = ref.watch(selectedContextProvider);
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final feedback = ref.watch(outfitFeedbackProvider);
    final auth = ref.watch(authControllerProvider);
    final focusedItem = ref.watch(focusedItemProvider);
    final weatherAsync = ref.watch(weatherRepositoryProvider).fetchTodayWeather();
    final closetItemsAsync = ref.watch(closetItemsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.recommendationTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            AppChipSelector<OutfitContext>(
              values: OutfitContext.values,
              selected: selectedContext,
              labelBuilder: (value) => value.label,
              onSelected: (value) => ref.read(selectedContextProvider.notifier).state = value,
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              future: weatherAsync,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final weather = snapshot.data!;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weather.sourceLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${weather.summary} · ${weather.feelsLike.toStringAsFixed(0)}°',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '강수확률 ${(weather.precipitationProbability * 100).round()}% · 바람 ${weather.windSpeed.toStringAsFixed(0)}',
                      ),
                      if (weather.isFallback && weather.debugReason != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '원격 날씨를 불러오지 못해 샘플 데이터를 표시 중입니다: ${weather.debugReason}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red.shade400,
                              ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            if (focusedItem != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2DD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text('선택 아이템 중심 추천: ${focusedItem.title}')),
                    TextButton(
                      onPressed: () => ref.read(focusedItemProvider.notifier).state = null,
                      child: const Text('해제'),
                    ),
                  ],
                ),
              ),
            if (feedback.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '최근 피드백: ${feedback.first.feedbackType} · ${feedback.first.recommendationTitle}',
                ),
              ),
            const SizedBox(height: 16),
            if (auth.valueOrNull?.isAuthenticated == true)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('원격 옷장 데이터와 함께 추천을 계산 중입니다.'),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(shellTabProvider.notifier).state = 2,
                    child: const Text('빠른 등록'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(shellTabProvider.notifier).state = 1,
                    child: const Text('옷장 열기'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(shellTabProvider.notifier).state = 3,
                    child: const Text('기록 보기'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: recommendationsAsync.when(
                data: (recommendations) {
                  if (recommendations.isEmpty) {
                    return _RecommendationEmptyState(
                      itemsAsync: closetItemsAsync,
                      focusedItem: focusedItem,
                    );
                  }
                  return ListView.separated(
                    itemCount: recommendations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final recommendation = recommendations[index];
                      return Column(
                        children: [
                          OutfitCard(
                            recommendation: recommendation,
                            onTapBreakdown: () => showModalBottomSheet<void>(
                              context: context,
                              builder: (_) => ScoreBreakdownSheet(
                                recommendation: recommendation,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FeedbackButton(
                                  label: '좋아요',
                                  onTap: () => ref
                                      .read(outfitFeedbackProvider.notifier)
                                      .saveFeedback(
                                        recommendationTitle: recommendation.title,
                                        feedbackType: 'like',
                                      ),
                                ),
                                _FeedbackButton(
                                  label: '별로예요',
                                  onTap: () => ref
                                      .read(outfitFeedbackProvider.notifier)
                                      .saveFeedback(
                                        recommendationTitle: recommendation.title,
                                        feedbackType: 'dislike',
                                      ),
                                ),
                                _FeedbackButton(
                                  label: '오늘 입었어요',
                                  onTap: () => ref
                                      .read(outfitFeedbackProvider.notifier)
                                      .saveFeedback(
                                        recommendationTitle: recommendation.title,
                                        feedbackType: 'worn',
                                      ),
                                ),
                                _FeedbackButton(
                                  label: '덜 포멀하게',
                                  onTap: () => ref
                                      .read(outfitFeedbackProvider.notifier)
                                      .saveFeedback(
                                        recommendationTitle: recommendation.title,
                                        feedbackType: 'less_formal',
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('추천을 불러오지 못했습니다: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationEmptyState extends StatelessWidget {
  const _RecommendationEmptyState({
    required this.itemsAsync,
    required this.focusedItem,
  });

  final AsyncValue<List<ClothingItem>> itemsAsync;
  final ClothingItem? focusedItem;

  @override
  Widget build(BuildContext context) {
    return itemsAsync.when(
      data: (items) {
        String reason;
        String alternative;
        final topCount = items.where((item) => item.category == ClothingCategory.top).length;
        final bottomCount = items.where((item) => item.category == ClothingCategory.bottom).length;
        final shoesCount = items.where((item) => item.category == ClothingCategory.shoes).length;
        final outerCount = items.where((item) => item.category == ClothingCategory.outer).length;
        final missing = <String>[
          if (topCount == 0) '상의',
          if (bottomCount == 0) '하의',
          if (shoesCount == 0) '신발',
        ];
        if (items.isEmpty) {
          reason = '아직 등록된 옷이 없어서 추천을 만들 수 없어요.';
          alternative = '먼저 상의, 하의, 신발부터 1개 이상 등록해보세요.';
        } else if (missing.isNotEmpty) {
          reason = '등록한 옷은 있지만 아직 코디를 만들 최소 구성이 부족해요.';
          alternative = '${missing.join(', ')}을(를) 1개 이상 추가하면 추천을 만들 수 있어요.';
          if (outerCount == 0) {
            alternative += ' 추운 날이나 비 오는 날 추천을 위해 아우터도 있으면 더 좋아요.';
          }
        } else if (focusedItem != null) {
          reason = '선택한 아이템과 조합할 다른 카테고리 아이템이 부족해요.';
          alternative = '다른 하의/신발 또는 아우터를 더 등록하거나 선택 아이템 중심 추천을 해제해보세요.';
        } else {
          reason = '현재 옷장 구성으로는 상의, 하의, 신발 조합이 완성되지 않아요.';
          alternative = '부족한 카테고리 아이템을 추가하거나 상황 선택을 바꿔보세요.';
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(reason, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(alternative, textAlign: TextAlign.center),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _ClosetStatusChip(label: '상의 $topCount'),
                      _ClosetStatusChip(label: '하의 $bottomCount'),
                      _ClosetStatusChip(label: '신발 $shoesCount'),
                      _ClosetStatusChip(label: '아우터 $outerCount'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('추천 사유를 불러오지 못했습니다: $error')),
    );
  }
}

class _ClosetStatusChip extends StatelessWidget {
  const _ClosetStatusChip({required this.label});

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

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
