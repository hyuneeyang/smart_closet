import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_strings.dart';
import '../features/history/presentation/history_page.dart';
import '../features/recommendation/data/recommendation_controller.dart';
import '../features/closet/presentation/closet_page.dart';
import '../features/closet/presentation/register_clothing_page.dart';
import '../features/recommendation/presentation/today_recommendation_page.dart';
import '../features/settings/presentation/settings_page.dart';

final shellTabProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(shellTabProvider);
    final auth = ref.watch(authControllerProvider);
    const pages = [
      TodayRecommendationPage(),
      ClosetPage(),
      RegisterClothingPage(),
      HistoryPage(),
      SettingsPage(),
    ];

    final titles = [
      AppStrings.appName,
      AppStrings.closetTitle,
      AppStrings.registerTitle,
      AppStrings.historyTitle,
      AppStrings.settingsTitle,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.valueOrNull?.isAuthenticated == true
              ? '${titles[tab]} · 저장 가능'
              : titles[tab],
        ),
        centerTitle: false,
      ),
      body: IndexedStack(
        index: tab,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => ref.read(shellTabProvider.notifier).state = value,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_cloudy_outlined),
            selectedIcon: Icon(Icons.wb_cloudy),
            label: '추천',
          ),
          NavigationDestination(
            icon: Icon(Icons.checkroom_outlined),
            selectedIcon: Icon(Icons.checkroom),
            label: AppStrings.closetTitle,
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: AppStrings.registerTitle,
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: AppStrings.historyTitle,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: AppStrings.settingsTitle,
          ),
        ],
      ),
    );
  }
}
