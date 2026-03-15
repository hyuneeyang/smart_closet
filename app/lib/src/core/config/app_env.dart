class AppEnv {
  const AppEnv({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.openWeatherApiKey,
    required this.openAiApiKey,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String openWeatherApiKey;
  final String openAiApiKey;

  static AppEnv fromDefines() {
    return const AppEnv(
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      openWeatherApiKey: String.fromEnvironment('OPENWEATHER_API_KEY'),
      openAiApiKey: String.fromEnvironment('OPENAI_API_KEY'),
    );
  }

  bool get hasSupabase => _isConfigured(supabaseUrl) && _isConfigured(supabaseAnonKey);
  bool get hasWeatherKey => _isConfigured(openWeatherApiKey);
  bool get hasOpenAiKey => _isConfigured(openAiApiKey);

  static bool _isConfigured(String value) {
    if (value.isEmpty) return false;
    final lowered = value.toLowerCase();
    return !lowered.contains('your-project') &&
        !lowered.contains('your-anon-key') &&
        !lowered.contains('your-openweather-key') &&
        !lowered.contains('your-openai-key');
  }
}
