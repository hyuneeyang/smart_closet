class TrendSignal {
  const TrendSignal({
    required this.keyword,
    required this.region,
    required this.score,
    required this.source,
    this.seasonHint,
  });

  final String keyword;
  final String region;
  final double score;
  final String source;
  final String? seasonHint;
}
