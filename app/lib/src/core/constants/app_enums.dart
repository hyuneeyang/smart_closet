enum ClothingCategory { top, bottom, outer, shoes, bag }

enum OutfitContext {
  work,
  daily,
  date,
  travel,
  workout,
  gathering,
  formal,
  rainy,
  cold,
  hot,
}

extension OutfitContextX on OutfitContext {
  String get label => switch (this) {
        OutfitContext.work => '출근',
        OutfitContext.daily => '데일리',
        OutfitContext.date => '데이트',
        OutfitContext.travel => '여행',
        OutfitContext.workout => '운동',
        OutfitContext.gathering => '모임',
        OutfitContext.formal => '격식 있는 자리',
        OutfitContext.rainy => '비 오는 날',
        OutfitContext.cold => '추운 날',
        OutfitContext.hot => '더운 날',
      };
}
