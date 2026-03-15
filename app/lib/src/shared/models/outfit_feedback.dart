class OutfitFeedback {
  const OutfitFeedback({
    required this.recommendationTitle,
    required this.feedbackType,
    required this.createdAt,
  });

  final String recommendationTitle;
  final String feedbackType;
  final DateTime createdAt;
}
