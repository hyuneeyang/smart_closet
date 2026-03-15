import '../../../core/constants/app_enums.dart';
import '../../../shared/models/clothing_item.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../shared/models/wear_record.dart';

class MockClosetDataSource {
  Future<List<ClothingItem>> fetchItems() async {
    return const [
      ClothingItem(
        id: 'top_1',
        title: '베이지 니트',
        category: ClothingCategory.top,
        primaryColor: 'beige',
        styleTags: ['minimal', 'classic', 'cleanfit'],
        warmthScore: 0.78,
        formalityScore: 0.64,
        waterproof: false,
        imageUrl: 'https://picsum.photos/seed/top1/300/300',
      ),
      ClothingItem(
        id: 'top_2',
        title: '화이트 셔츠',
        category: ClothingCategory.top,
        primaryColor: 'white',
        styleTags: ['formal', 'classic', 'minimal'],
        warmthScore: 0.42,
        formalityScore: 0.82,
        waterproof: false,
        imageUrl: 'https://picsum.photos/seed/top2/300/300',
      ),
      ClothingItem(
        id: 'bottom_1',
        title: '네이비 슬랙스',
        category: ClothingCategory.bottom,
        primaryColor: 'navy',
        styleTags: ['classic', 'formal', 'minimal'],
        warmthScore: 0.48,
        formalityScore: 0.80,
        waterproof: false,
        imageUrl: 'https://picsum.photos/seed/bottom1/300/300',
      ),
      ClothingItem(
        id: 'bottom_2',
        title: '올리브 조거 팬츠',
        category: ClothingCategory.bottom,
        primaryColor: 'olive',
        styleTags: ['casual', 'sporty', 'gorp'],
        warmthScore: 0.44,
        formalityScore: 0.25,
        waterproof: false,
        imageUrl: 'https://picsum.photos/seed/bottom2/300/300',
      ),
      ClothingItem(
        id: 'outer_1',
        title: '트렌치코트',
        category: ClothingCategory.outer,
        primaryColor: 'camel',
        styleTags: ['classic', 'minimal', 'oldmoney'],
        warmthScore: 0.72,
        formalityScore: 0.70,
        waterproof: true,
        imageUrl: 'https://picsum.photos/seed/outer1/300/300',
      ),
      ClothingItem(
        id: 'outer_2',
        title: '윈드브레이커',
        category: ClothingCategory.outer,
        primaryColor: 'charcoal',
        styleTags: ['sporty', 'gorp', 'casual'],
        warmthScore: 0.58,
        formalityScore: 0.22,
        waterproof: true,
        imageUrl: 'https://picsum.photos/seed/outer2/300/300',
      ),
      ClothingItem(
        id: 'shoes_1',
        title: '브라운 로퍼',
        category: ClothingCategory.shoes,
        primaryColor: 'brown',
        styleTags: ['classic', 'formal'],
        warmthScore: 0.34,
        formalityScore: 0.84,
        waterproof: false,
        imageUrl: 'https://picsum.photos/seed/shoes1/300/300',
      ),
      ClothingItem(
        id: 'shoes_2',
        title: '화이트 스니커즈',
        category: ClothingCategory.shoes,
        primaryColor: 'white',
        styleTags: ['casual', 'cleanfit', 'minimal'],
        warmthScore: 0.30,
        formalityScore: 0.36,
        waterproof: false,
        imageUrl: 'https://picsum.photos/seed/shoes2/300/300',
      ),
    ];
  }

  Future<List<WearRecord>> fetchWearHistory() async {
    final now = DateTime.now();
    return [
      WearRecord(
        itemId: 'top_2',
        wornAt: now.subtract(const Duration(days: 2)),
        context: OutfitContext.work,
      ),
      WearRecord(
        itemId: 'bottom_1',
        wornAt: now.subtract(const Duration(days: 1)),
        context: OutfitContext.work,
      ),
      WearRecord(
        itemId: 'shoes_2',
        wornAt: now.subtract(const Duration(days: 3)),
        context: OutfitContext.daily,
      ),
    ];
  }

  Future<UserPreferences> fetchPreferences() async {
    return const UserPreferences(
      preferredStyleTags: ['minimal', 'classic', 'cleanfit'],
      preferredColors: ['beige', 'navy', 'white', 'brown'],
      frequentContexts: [OutfitContext.work, OutfitContext.daily],
    );
  }
}
