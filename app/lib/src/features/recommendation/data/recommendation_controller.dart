import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_env.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/storage/local_session_store.dart';
import '../../../shared/models/outfit_recommendation.dart';
import '../../../shared/models/outfit_feedback.dart';
import '../../../shared/models/clothing_item.dart';
import '../../../shared/models/auth_state.dart';
import '../../../shared/models/weather_snapshot.dart';
import '../../../shared/models/user_preferences.dart';
import '../../ai/data/mock_clothing_analysis_service.dart';
import '../../ai/data/openai_clothing_analysis_service.dart';
import '../../ai/domain/clothing_analysis_service.dart';
import '../../auth/data/fallback_auth_repository.dart';
import '../../auth/data/mock_auth_repository.dart';
import '../../auth/data/supabase_auth_repository.dart';
import '../../auth/data/supabase_user_bootstrap_data_source.dart';
import '../../auth/domain/auth_repository.dart';
import '../../closet/data/clothing_registration_repository_impl.dart';
import '../../closet/data/empty_closet_repository_impl.dart';
import '../../closet/data/fallback_closet_repository_impl.dart';
import '../../closet/data/remote_closet_repository_impl.dart';
import '../../closet/data/supabase_closet_data_source.dart';
import '../../closet/domain/closet_repository.dart';
import '../../closet/domain/clothing_registration_repository.dart';
import '../../closet/domain/register_clothing_item_use_case.dart';
import '../../storage/data/mock_storage_repository.dart';
import '../../storage/data/supabase_storage_repository.dart';
import '../../storage/domain/storage_repository.dart';
import 'supabase_feedback_data_source.dart';
import '../../trend/data/fallback_trend_repository_impl.dart';
import '../../trend/data/mock_trend_data_source.dart';
import '../../trend/data/remote_trend_data_source.dart';
import '../../trend/data/remote_trend_repository_impl.dart';
import '../../trend/data/trend_repository_impl.dart';
import '../../trend/domain/trend_repository.dart';
import '../../weather/data/device_location_provider.dart';
import '../../weather/data/fallback_weather_repository.dart';
import '../../weather/data/mock_weather_data_source.dart';
import '../../weather/data/openweather_api_service.dart';
import '../../weather/data/remote_weather_repository_impl.dart';
import '../../weather/data/weather_repository_impl.dart';
import '../../weather/domain/weather_repository.dart';
import '../domain/recommendation_engine.dart';

final selectedContextProvider = StateProvider<OutfitContext>((ref) => OutfitContext.work);
final focusedItemProvider = StateProvider<ClothingItem?>((ref) => null);

final appEnvProvider = Provider<AppEnv>((ref) => AppEnv.fromDefines());

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  final env = ref.watch(appEnvProvider);
  if (!env.hasSupabase) return null;
  return Supabase.instance.client;
});

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final fallback = MockAuthRepository(
    localSessionStore: ref.watch(localSessionStoreProvider),
  );
  if (client == null) return fallback;
  return FallbackAuthRepository(
    primary: SupabaseAuthRepository(
      client,
      bootstrapDataSource: SupabaseUserBootstrapDataSource(client),
    ),
    fallback: fallback,
  );
});

final localSessionStoreProvider = Provider<LocalSessionStore>((ref) => LocalSessionStore());

final authStateProvider = FutureProvider<AuthStateSnapshot>((ref) {
  return ref.watch(authRepositoryProvider).getCurrentAuthState();
});

final authStateChangesProvider = Provider<Stream<AuthState>?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client?.auth.onAuthStateChange;
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthStateSnapshot>>(
  (ref) => AuthController(
    ref.watch(authRepositoryProvider),
    authStateChanges: ref.watch(authStateChangesProvider),
  ),
);

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authState = ref.watch(authControllerProvider).valueOrNull;
  if (client == null || authState == null || !authState.isRemote || authState.userId == null) {
    return MockStorageRepository();
  }
  return SupabaseStorageRepository(client);
});

final closetRepositoryProvider = Provider<ClosetRepository>((ref) {
  final fallback = EmptyClosetRepositoryImpl();
  final authState = ref.watch(authControllerProvider).valueOrNull;
  final client = ref.watch(supabaseClientProvider);

  if (client == null ||
      authState == null ||
      !authState.isAuthenticated ||
      !authState.isRemote ||
      authState.userId == null) {
    return fallback;
  }

  final remote = RemoteClosetRepositoryImpl(
    dataSource: SupabaseClosetDataSource(client),
    userId: authState.userId!,
  );
  return FallbackClosetRepositoryImpl(primary: remote, fallback: fallback);
});

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final env = ref.watch(appEnvProvider);
  final fallback = WeatherRepositoryImpl(MockWeatherDataSource());

  if (!env.hasWeatherKey) return fallback;

  final remote = RemoteWeatherRepositoryImpl(
    service: OpenWeatherApiService(
      client: ref.watch(httpClientProvider),
      apiKey: env.openWeatherApiKey,
    ),
    locationProvider: DeviceLocationProvider(),
  );

  return FallbackWeatherRepository(primary: remote, fallback: fallback);
});

final trendRepositoryProvider = Provider<TrendRepository>((ref) {
  final fallback = TrendRepositoryImpl(MockTrendDataSource());
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return fallback;
  final remote = RemoteTrendRepositoryImpl(RemoteTrendDataSource(client));
  return FallbackTrendRepositoryImpl(primary: remote, fallback: fallback);
});

final clothingAnalysisServiceProvider = Provider<ClothingAnalysisService>((ref) {
  final env = ref.watch(appEnvProvider);
  if (!env.hasOpenAiKey) return MockClothingAnalysisService();

  return OpenAiClothingAnalysisService(
    client: ref.watch(httpClientProvider),
    apiKey: env.openAiApiKey,
  );
});

final clothingRegistrationRepositoryProvider = Provider<ClothingRegistrationRepository>(
  (ref) {
    final client = ref.watch(supabaseClientProvider);
    final authState = ref.watch(authControllerProvider).valueOrNull;
    final isRemoteAuth = authState?.isRemote == true && authState?.userId != null;
    return ClothingRegistrationRepositoryImpl(
      ref.watch(clothingAnalysisServiceProvider),
      remoteDataSource: client != null && isRemoteAuth ? SupabaseClosetDataSource(client) : null,
      userId: isRemoteAuth ? authState!.userId : null,
      storageRepository: ref.watch(storageRepositoryProvider),
    );
  },
);

final registerClothingItemUseCaseProvider = Provider<RegisterClothingItemUseCase>(
  (ref) => RegisterClothingItemUseCase(
    ref.watch(clothingRegistrationRepositoryProvider),
  ),
);

final recommendationEngineProvider = Provider<RecommendationEngine>(
  (ref) => RecommendationEngine(),
);

final localClosetItemsProvider =
    StateNotifierProvider<LocalClosetItemsController, List<ClothingItem>>(
  (ref) => LocalClosetItemsController(ref.watch(localSessionStoreProvider)),
);

final closetItemUpdateProvider = Provider<ClosetItemUpdateService>(
  (ref) => ClosetItemUpdateService(
    localController: ref.watch(localClosetItemsProvider.notifier),
    remoteDataSource: ref.watch(supabaseClientProvider) != null &&
            ref.watch(authControllerProvider).valueOrNull?.isRemote == true
        ? SupabaseClosetDataSource(ref.watch(supabaseClientProvider)!)
        : null,
  ),
);

final adaptivePreferencesProvider =
    StateNotifierProvider<AdaptivePreferencesController, UserPreferences>(
  (ref) => AdaptivePreferencesController(),
);

final recommendationHistoryProvider =
    StateNotifierProvider<RecommendationHistoryController, List<OutfitRecommendation>>(
  (ref) => RecommendationHistoryController(),
);

final appSettingsProvider = StateNotifierProvider<AppSettingsController, AppSettings>(
  (ref) => AppSettingsController(),
);

final closetItemsProvider = FutureProvider<List<ClothingItem>>((ref) async {
  final baseItems = await ref.watch(closetRepositoryProvider).fetchClothingItems();
  final localItems = ref.watch(localClosetItemsProvider);
  final merged = {
    for (final item in baseItems) item.id: item,
    for (final item in localItems) item.id: item,
  };
  return merged.values.toList()
    ..sort((a, b) => b.id.compareTo(a.id));
});

final outfitFeedbackProvider =
    StateNotifierProvider<OutfitFeedbackController, List<OutfitFeedback>>(
  (ref) => OutfitFeedbackController(
    feedbackDataSource: ref.watch(supabaseClientProvider) != null &&
            ref.watch(authControllerProvider).valueOrNull?.isRemote == true
        ? SupabaseFeedbackDataSource(ref.watch(supabaseClientProvider)!)
        : null,
    authState: ref.watch(authControllerProvider).valueOrNull,
    preferencesController: ref.watch(adaptivePreferencesProvider.notifier),
  ),
);

final recommendationsProvider = FutureProvider<List<OutfitRecommendation>>((ref) async {
  final context = ref.watch(selectedContextProvider);
  final focusedItem = ref.watch(focusedItemProvider);
  final closetRepository = ref.watch(closetRepositoryProvider);
  final weatherRepository = ref.watch(weatherRepositoryProvider);
  final trendRepository = ref.watch(trendRepositoryProvider);
  final engine = ref.watch(recommendationEngineProvider);

  final items = await ref.watch(closetItemsProvider.future).timeout(
        const Duration(seconds: 3),
        onTimeout: () => ref.read(localClosetItemsProvider),
      );
  final wearHistory = await closetRepository.fetchWearHistory().timeout(
        const Duration(seconds: 3),
        onTimeout: () => const [],
      );
  final preferences = await closetRepository.fetchUserPreferences().timeout(
        const Duration(seconds: 3),
        onTimeout: () => const UserPreferences(
          preferredStyleTags: ['minimal', 'classic'],
          preferredColors: ['white', 'beige', 'navy'],
          frequentContexts: [],
        ),
      );
  final adaptivePreferences = ref.watch(adaptivePreferencesProvider);
  final weather = await weatherRepository.fetchTodayWeather().timeout(
        const Duration(seconds: 4),
        onTimeout: () => const WeatherSnapshot(
          summary: '날씨 정보를 확인할 수 없어요',
          temperature: 0,
          feelsLike: 0,
          precipitationProbability: 0,
          windSpeed: 0,
          hourlyForecast: [],
          isFallback: true,
          sourceLabel: '샘플 날씨',
          debugReason: '추천 계산 중 날씨 조회 시간 초과',
        ),
      );
  final trends = await trendRepository.fetchTrendSignals().timeout(
        const Duration(seconds: 3),
        onTimeout: () => const [],
      );

  final recommendations = engine.recommend(
    items: items,
    weather: weather,
    context: context,
    wearHistory: wearHistory,
    preferences: _mergePreferences(preferences, adaptivePreferences),
    trendSignals: trends,
    focusedItem: focusedItem,
  );
  ref.read(recommendationHistoryProvider.notifier).remember(recommendations);
  return recommendations;
});

class OutfitFeedbackController extends StateNotifier<List<OutfitFeedback>> {
  OutfitFeedbackController({
    this.feedbackDataSource,
    this.authState,
    this.preferencesController,
  }) : super(const []);

  final SupabaseFeedbackDataSource? feedbackDataSource;
  final AuthStateSnapshot? authState;
  final AdaptivePreferencesController? preferencesController;

  Future<void> saveFeedback({
    required String recommendationTitle,
    required String feedbackType,
  }) async {
    state = [
      OutfitFeedback(
        recommendationTitle: recommendationTitle,
        feedbackType: feedbackType,
        createdAt: DateTime.now(),
      ),
      ...state,
    ];

    final userId = authState?.userId;
    if (feedbackDataSource != null && userId != null && userId.isNotEmpty) {
      try {
        await feedbackDataSource!.saveFeedback(
          userId: userId,
          recommendationTitle: recommendationTitle,
          feedbackType: feedbackType,
        );
      } catch (_) {
        // Keep local feedback even if remote persistence fails.
      }
    }

    preferencesController?.applyFeedback(feedbackType);
  }
}

class LocalClosetItemsController extends StateNotifier<List<ClothingItem>> {
  LocalClosetItemsController(this._localSessionStore) : super(const []) {
    _load();
  }

  final LocalSessionStore _localSessionStore;

  Future<void> _load() async {
    state = await _localSessionStore.loadLocalClosetItems();
  }

  void addItem(ClothingItem item) {
    state = [item, ...state];
    _persist();
  }

  void upsertItem(ClothingItem item) {
    final index = state.indexWhere((existing) => existing.id == item.id);
    if (index == -1) {
      state = [item, ...state];
      _persist();
      return;
    }

    final updated = [...state];
    updated[index] = item;
    state = updated;
    _persist();
  }

  void deleteItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
    _persist();
  }

  void _persist() {
    unawaited(_localSessionStore.saveLocalClosetItems(state));
  }
}

class ClosetItemUpdateService {
  ClosetItemUpdateService({
    required this.localController,
    required this.remoteDataSource,
  });

  final LocalClosetItemsController localController;
  final SupabaseClosetDataSource? remoteDataSource;

  Future<void> updateItem(ClothingItem item) async {
    localController.upsertItem(item);
    if (!item.id.startsWith('local_') && remoteDataSource != null) {
      try {
        await remoteDataSource!.updateClothingItem(item: item);
      } catch (_) {
        // Keep local change even when remote persistence fails.
      }
    }
  }

  Future<void> deleteItem(ClothingItem item) async {
    localController.deleteItem(item.id);
    if (!item.id.startsWith('local_') && remoteDataSource != null) {
      try {
        await remoteDataSource!.deleteClothingItem(itemId: item.id);
      } catch (_) {
        // Keep local deletion even when remote delete fails.
      }
    }
  }
}

class AdaptivePreferencesController extends StateNotifier<UserPreferences> {
  AdaptivePreferencesController()
      : super(
          const UserPreferences(
            preferredStyleTags: [],
            preferredColors: [],
            frequentContexts: [],
          ),
        );

  void applyFeedback(String feedbackType) {
    if (feedbackType == 'less_formal') {
      state = UserPreferences(
        preferredStyleTags: {...state.preferredStyleTags, 'casual', 'cleanfit'}.toList(),
        preferredColors: state.preferredColors,
        frequentContexts: state.frequentContexts,
      );
    }
    if (feedbackType == 'like' || feedbackType == 'worn') {
      state = UserPreferences(
        preferredStyleTags: {...state.preferredStyleTags, 'minimal', 'classic'}.toList(),
        preferredColors: {...state.preferredColors, 'white', 'navy'}.toList(),
        frequentContexts: state.frequentContexts,
      );
    }
  }
}

class RecommendationHistoryController extends StateNotifier<List<OutfitRecommendation>> {
  RecommendationHistoryController() : super(const []);

  void remember(List<OutfitRecommendation> recommendations) {
    final combined = [...recommendations, ...state];
    final unique = <String, OutfitRecommendation>{};
    for (final recommendation in combined) {
      unique['${recommendation.title}-${recommendation.context.name}-${recommendation.totalScore}'] =
          recommendation;
    }
    state = unique.values.take(20).toList();
  }
}

class AppSettings {
  const AppSettings({
    required this.locationEnabled,
    required this.notificationEnabled,
    required this.preferredStyleTags,
    required this.recommendationStrength,
  });

  final bool locationEnabled;
  final bool notificationEnabled;
  final List<String> preferredStyleTags;
  final double recommendationStrength;

  AppSettings copyWith({
    bool? locationEnabled,
    bool? notificationEnabled,
    List<String>? preferredStyleTags,
    double? recommendationStrength,
  }) {
    return AppSettings(
      locationEnabled: locationEnabled ?? this.locationEnabled,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      preferredStyleTags: preferredStyleTags ?? this.preferredStyleTags,
      recommendationStrength: recommendationStrength ?? this.recommendationStrength,
    );
  }
}

class AppSettingsController extends StateNotifier<AppSettings> {
  AppSettingsController()
      : super(
          const AppSettings(
            locationEnabled: true,
            notificationEnabled: false,
            preferredStyleTags: ['minimal', 'classic'],
            recommendationStrength: 0.6,
          ),
        );

  void setLocationEnabled(bool value) => state = state.copyWith(locationEnabled: value);
  void setNotificationEnabled(bool value) => state = state.copyWith(notificationEnabled: value);
  void setRecommendationStrength(double value) =>
      state = state.copyWith(recommendationStrength: value);

  void toggleStyle(String tag) {
    final styles = [...state.preferredStyleTags];
    if (styles.contains(tag)) {
      styles.remove(tag);
    } else {
      styles.add(tag);
    }
    state = state.copyWith(preferredStyleTags: styles);
  }
}

UserPreferences _mergePreferences(
  UserPreferences base,
  UserPreferences adaptive,
) {
  return UserPreferences(
    preferredStyleTags: {...base.preferredStyleTags, ...adaptive.preferredStyleTags}.toList(),
    preferredColors: {...base.preferredColors, ...adaptive.preferredColors}.toList(),
    frequentContexts: {...base.frequentContexts, ...adaptive.frequentContexts}.toList(),
  );
}

class AuthController extends StateNotifier<AsyncValue<AuthStateSnapshot>> {
  AuthController(
    this._repository, {
    Stream<AuthState>? authStateChanges,
  }) : super(const AsyncValue.loading()) {
    _subscription = authStateChanges?.listen((_) => _load());
    _load();
  }

  final AuthRepository _repository;
  StreamSubscription<AuthState>? _subscription;

  Future<void> _load() async {
    final current = await AsyncValue.guard(_repository.getCurrentAuthState);
    final authState = current.valueOrNull;
    if (authState != null && !authState.isAuthenticated) {
      final autoSignIn = await AsyncValue.guard(_repository.signInAnonymously);
      state = autoSignIn;
      final signedInState = autoSignIn.valueOrNull;
      if (signedInState != null) {
        unawaited(_bootstrapSafely(signedInState));
      }
      return;
    }

    state = current;
    if (authState != null) {
      unawaited(_bootstrapSafely(authState));
    }
  }

  Future<void> signIn() async {
    final result = await AsyncValue.guard(_repository.signInAnonymously);
    state = result;
    final authState = result.valueOrNull;
    if (authState != null) {
      unawaited(_bootstrapSafely(authState));
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(_repository.signInWithGoogle);
    state = result;
    final authState = result.valueOrNull;
    if (authState != null) {
      unawaited(_bootstrapSafely(authState));
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _repository.signInWithEmail(email: email, password: password),
    );
    state = result;
    final authState = result.valueOrNull;
    if (authState != null) {
      unawaited(_bootstrapSafely(authState));
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _repository.signUpWithEmail(email: email, password: password),
    );
    state = result;
    final authState = result.valueOrNull;
    if (authState != null) {
      unawaited(_bootstrapSafely(authState));
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncValue.data(AuthStateSnapshot(isAuthenticated: false, isRemote: false));
  }

  Future<void> _bootstrapSafely(AuthStateSnapshot authState) async {
    try {
      await _repository.bootstrapUserProfile(authState);
    } catch (_) {
      // Keep auth usable even if profile bootstrap fails.
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
