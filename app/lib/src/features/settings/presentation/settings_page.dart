import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../recommendation/data/recommendation_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SwitchListTile(
          value: settings.locationEnabled,
          onChanged: (value) => ref.read(appSettingsProvider.notifier).setLocationEnabled(value),
          title: const Text('위치'),
          subtitle: const Text('현재 위치 날씨를 추천에 사용'),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          value: settings.notificationEnabled,
          onChanged: (value) =>
              ref.read(appSettingsProvider.notifier).setNotificationEnabled(value),
          title: const Text('알림'),
          subtitle: const Text('추천 알림 받기'),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 20),
        Text('스타일 선호', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['minimal', 'classic', 'cleanfit', 'casual', 'sporty'].map((tag) {
            return FilterChip(
              label: Text(tag),
              selected: settings.preferredStyleTags.contains(tag),
              onSelected: (_) => ref.read(appSettingsProvider.notifier).toggleStyle(tag),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          '추천 강도 ${settings.recommendationStrength.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Slider(
          value: settings.recommendationStrength,
          onChanged: (value) =>
              ref.read(appSettingsProvider.notifier).setRecommendationStrength(value),
        ),
      ],
    );
  }
}
