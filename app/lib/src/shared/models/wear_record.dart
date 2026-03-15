import '../../core/constants/app_enums.dart';

class WearRecord {
  const WearRecord({
    required this.itemId,
    required this.wornAt,
    required this.context,
  });

  final String itemId;
  final DateTime wornAt;
  final OutfitContext context;
}
