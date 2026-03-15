import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseUserBootstrapDataSource {
  SupabaseUserBootstrapDataSource(this._client);

  final SupabaseClient _client;

  Future<void> ensureUserProfile({
    required String userId,
    String? email,
  }) async {
    await _client.from('users').upsert({
      'id': userId,
      'nickname': email?.split('@').first ?? 'closet-user',
      'locale': 'ko-KR',
    });

    final preferences = await _client
        .from('user_preferences')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (preferences == null) {
      await _client.from('user_preferences').insert({
        'user_id': userId,
        'preferred_style_tags': ['minimal', 'classic'],
        'preferred_colors': ['white', 'beige', 'navy'],
        'frequent_contexts': ['daily', 'work'],
        'dislike_style_tags': <String>[],
      });
    }
  }
}
