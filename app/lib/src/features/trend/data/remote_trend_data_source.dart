import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/trend_signal.dart';

class RemoteTrendDataSource {
  RemoteTrendDataSource(this._client);

  final SupabaseClient _client;

  Future<List<TrendSignal>> fetchTrendSignals({
    String region = 'KR',
    int limit = 40,
  }) async {
    final rows = await _client
        .from('trend_signals')
        .select()
        .eq('region', region)
        .order('date', ascending: false)
        .limit(limit);

    final latestByKeyword = <String, TrendSignal>{};
    for (final row in rows as List<dynamic>) {
      final map = row as Map<String, dynamic>;
      final keyword = map['keyword']?.toString() ?? '';
      if (keyword.isEmpty || latestByKeyword.containsKey(keyword)) {
        continue;
      }

      latestByKeyword[keyword] = TrendSignal(
        keyword: keyword,
        region: map['region']?.toString() ?? region,
        score: (map['score'] as num?)?.toDouble() ?? 0,
        source: map['source']?.toString() ?? 'supabase',
        seasonHint: map['season_hint']?.toString(),
      );
    }

    return latestByKeyword.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }
}
