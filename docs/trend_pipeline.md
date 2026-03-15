# Trend Pipeline

`trend_signals`는 추천 엔진이 읽는 내부 정규화 테이블이다.

## 목적

- 외부 API 형식이 바뀌어도 앱은 `trend_signals`만 읽는다.
- 트렌드는 보조 신호이므로 수집 실패 시에도 추천은 계속 동작한다.
- 공급자별 raw 응답을 바로 추천 로직에 넣지 않는다.

## 현재 구조

1. Edge Function
   - `/Users/hyunjessieyang/Documents/Playground/supabase/functions/trend-signals-sync/index.ts`
2. 공급자 어댑터
   - `GOOGLE_TRENDS_ENDPOINT`
   - `PINTEREST_TRENDS_ENDPOINT`
   - `TIKTOK_TRENDS_ENDPOINT`
   - `internal_dictionary`
3. 정규화
   - `keyword`
   - `region`
   - `date`
   - `score`
   - `source`
   - `season_hint`
4. 앱 조회
   - `/Users/hyunjessieyang/Documents/Playground/app/lib/src/features/trend/data/remote_trend_data_source.dart`

## 외부 endpoint 계약

각 공급자 endpoint는 아래 형식으로 응답하면 된다.

```json
{
  "data": [
    {
      "keyword": "minimal",
      "score": 0.84,
      "region": "KR",
      "source": "google_trends",
      "date": "2026-03-15",
      "season_hint": "spring"
    }
  ]
}
```

## 추천 엔진 반영

- 앱은 `styleTags`와 `trend_signals.keyword`를 매칭한다.
- 반영 위치:
  - `/Users/hyunjessieyang/Documents/Playground/app/lib/src/features/recommendation/data/recommendation_controller.dart`
  - `/Users/hyunjessieyang/Documents/Playground/app/lib/src/features/recommendation/domain/recommendation_engine.dart`
- 가중치:
  - `trendMatch * 0.10`

## 운영 권장

- Google Trends alpha 또는 사내 프록시 endpoint
- Pinterest Trends 파트너/사내 수집 endpoint
- TikTok 트렌드/상업 콘텐츠 사내 수집 endpoint
- 아무 공급자도 실패하면 `internal_dictionary`만 적재
