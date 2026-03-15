import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseFeedbackDataSource {
  SupabaseFeedbackDataSource(this._client);

  final SupabaseClient _client;

  Future<void> saveFeedback({
    required String userId,
    required String recommendationTitle,
    required String feedbackType,
  }) async {
    final inserted = await _client
        .from('outfit_recommendations')
        .insert({
          'user_id': userId,
          'context': 'daily',
          'title': recommendationTitle,
          'total_score': 0,
          'score_breakdown': <String, dynamic>{},
          'explanation_text': 'feedback anchor',
        })
        .select('id')
        .single();

    await _client.from('outfit_feedback').insert({
      'recommendation_id': inserted['id'],
      'user_id': userId,
      'feedback_type': feedbackType,
    });
  }
}
