import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_enums.dart';
import '../../recommendation/data/recommendation_controller.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedback = ref.watch(outfitFeedbackProvider);
    final history = ref.watch(recommendationHistoryProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          Text('오늘 입은 옷', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ..._sectionEntries(
            feedback.where((entry) => entry.feedbackType == 'worn').map((entry) => entry.recommendationTitle),
            empty: '아직 오늘 입은 옷 기록이 없어요.',
          ),
          const SizedBox(height: 24),
          Text('최근 추천 내역', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (history.isEmpty)
            const Text('최근 추천 내역이 없어요.')
          else
            ...history.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.title),
                subtitle: Text('${entry.context.label} · ${(entry.totalScore * 100).round()}점'),
              ),
            ),
          const SizedBox(height: 24),
          Text('피드백 내역', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ..._sectionEntries(
            feedback.map((entry) => '${entry.feedbackType} · ${entry.recommendationTitle}'),
            empty: '피드백 내역이 없어요.',
          ),
        ],
      ),
    );
  }

  List<Widget> _sectionEntries(Iterable<String> entries, {required String empty}) {
    final values = entries.toList();
    if (values.isEmpty) return [Text(empty)];
    return values
        .map((text) => ListTile(contentPadding: EdgeInsets.zero, title: Text(text)))
        .toList();
  }
}
