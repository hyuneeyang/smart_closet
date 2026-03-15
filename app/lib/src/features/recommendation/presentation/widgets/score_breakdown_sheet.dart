import 'package:flutter/material.dart';

import '../../../../shared/models/outfit_recommendation.dart';

class ScoreBreakdownSheet extends StatelessWidget {
  const ScoreBreakdownSheet({
    super.key,
    required this.recommendation,
  });

  final OutfitRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final breakdown = recommendation.breakdown;
    final items = <String, double>{
      '날씨 적합성': breakdown.weatherFit,
      '상황 적합성': breakdown.contextFit,
      '색상 조합': breakdown.colorHarmony,
      '취향 반영': breakdown.userPreference,
      '트렌드 참고': breakdown.trendMatch,
      '구성 완성도': breakdown.closetCompleteness,
      '최근 착용 패널티': -breakdown.recentWearPenalty,
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('점수 상세', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...items.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text((entry.value * 100).toStringAsFixed(0)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
