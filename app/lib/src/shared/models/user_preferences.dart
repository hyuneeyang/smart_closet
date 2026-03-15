import '../../core/constants/app_enums.dart';

class UserPreferences {
  const UserPreferences({
    required this.preferredStyleTags,
    required this.preferredColors,
    required this.frequentContexts,
  });

  final List<String> preferredStyleTags;
  final List<String> preferredColors;
  final List<OutfitContext> frequentContexts;
}
