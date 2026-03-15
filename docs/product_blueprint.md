# Smart Closet Product Blueprint

## 1. 요구사항 정리

### 제품 목표

- 사용자의 실제 옷장 데이터를 저장한다.
- 업로드 이미지 또는 웹 링크로 의류를 등록한다.
- AI 분석과 수동 수정으로 의류 메타데이터를 정제한다.
- 현재 날씨와 단기 예보, 사용 상황을 반영해 코디를 추천한다.
- 추천 결과를 텍스트가 아닌 실제 의류 이미지 조합형 코디 카드로 보여준다.
- 추천 이유와 점수 분해를 함께 제공한다.
- 트렌드는 보조 참고 신호로만 반영한다.

### 핵심 사용자 시나리오

1. 사용자가 온보딩에서 선호 스타일과 주 사용 상황을 고른다.
2. 옷장에 상의/하의/아우터/신발 이미지를 등록한다.
3. 홈에서 오늘 날씨와 상황 칩을 선택한다.
4. 앱이 추천 코디 3개와 점수, 이유를 코디 카드로 제시한다.
5. 사용자가 피드백을 남기고 추천 품질이 점진적으로 보정된다.

### 비기능 요구사항

- 한국어 UI 기본
- 로딩/빈 상태/에러 상태 포함
- 외부 API 실패 시 fallback 제공
- 테스트 가능한 구조
- 실사용 가능한 추천 품질을 위한 explainability 우선

## 2. MVP 범위와 2단계 품질 기능

### MVP

- mock 기반 옷장 조회
- 상황 선택
- mock 날씨 조회
- rule-based 추천 엔진
- 추천 3개 생성
- 코디 카드 UI
- 추천 이유 및 score breakdown 표시
- 착용 이력 기반 최근 착용 패널티
- 트렌드 reference signal 반영

### 2단계 품질 기능

- Supabase Auth/Storage 실연동
- OpenWeather 실연동
- OpenAI Vision 기반 의류 속성 추출
- 링크 파싱 및 쇼핑몰 메타데이터 수집
- 사용자 피드백 기반 선호도 업데이트
- 백그라운드 알림
- 이미지 배경제거/카드 렌더 캐싱
- 추천 결과 저장 및 히스토리 비교

## 3. 전체 시스템 아키텍처

### 클라이언트

- Flutter
- Riverpod
- Clean Architecture
- feature-first modules

### 백엔드

- Supabase Auth
- Postgres
- Supabase Storage
- Edge Functions or app server for trend/weather aggregation

### 추천 플로우

1. 옷장 아이템 로드
2. 날씨 스냅샷 로드
3. 선택 상황 확인
4. 최근 착용 기록 로드
5. 트렌드 신호 로드
6. 후보 조합 생성
7. 점수 계산
8. 상위 3개 코디 생성
9. 코디 카드 렌더링

### 계층 구조

- Presentation: page, view model, widgets
- Domain: entities, use cases, scoring policy
- Data: repositories, DTO, mock/remote source

## 4. Flutter 프로젝트 디렉토리 구조

```text
app/
  lib/
    main.dart
    src/
      app/
        app.dart
        app_shell.dart
      core/
        constants/
          app_enums.dart
          app_strings.dart
        config/
          app_env.dart
        theme/
          app_theme.dart
      features/
        ai/
          data/
            mock_clothing_analysis_service.dart
            openai_clothing_analysis_service.dart
          domain/
            clothing_analysis_service.dart
        closet/
          data/
            closet_repository_impl.dart
            clothing_registration_repository_impl.dart
            mock_closet_data_source.dart
            supabase_closet_data_source.dart
          domain/
            closet_repository.dart
            clothing_registration_repository.dart
            register_clothing_item_use_case.dart
          presentation/
            closet_page.dart
            clothing_item_detail_sheet.dart
            register_clothing_page.dart
        weather/
          data/
            fallback_weather_repository.dart
            weather_repository_impl.dart
            mock_weather_data_source.dart
            openweather_api_service.dart
            remote_weather_repository_impl.dart
          domain/
            weather_repository.dart
        trend/
          data/
            fallback_trend_repository_impl.dart
            trend_repository_impl.dart
            mock_trend_data_source.dart
            remote_trend_data_source.dart
            remote_trend_repository_impl.dart
          domain/
            trend_repository.dart
        recommendation/
          data/
            recommendation_controller.dart
          domain/
            recommendation_engine.dart
          presentation/
            today_recommendation_page.dart
            widgets/
              outfit_card.dart
              score_breakdown_sheet.dart
      shared/
        models/
          clothing_analysis.dart
          clothing_item.dart
          clothing_item_draft.dart
          hourly_weather.dart
          outfit_recommendation.dart
          outfit_feedback.dart
          trend_signal.dart
          weather_snapshot.dart
          wear_record.dart
          user_preferences.dart
        widgets/
          app_chip_selector.dart
  test/
    recommendation_engine_test.dart
```

## 5. DB schema

스키마는 `/Users/hyunjessieyang/Documents/Playground/docs/schema.sql` 참고.

## 6. 도메인 모델 정의

- `ClothingItem`: 옷장 아이템 메타데이터
- `WeatherSnapshot`: 현재 날씨/예보 요약
- `TrendSignal`: 스타일 키워드 인기도
- `WearRecord`: 착용 이력
- `UserPreferences`: 스타일/색상/상황 선호
- `OutfitRecommendation`: 추천 코디 집합, 점수 분해, 설명

## 7. 추천 엔진 설계

### 점수 공식

```text
total =
  weather_fit * 0.35 +
  context_fit * 0.25 +
  color_harmony * 0.15 +
  user_preference * 0.10 +
  trend_match * 0.10 +
  closet_completeness * 0.05 -
  recent_wear_penalty * 0.10
```

### 후보 생성 규칙

- 상의 1개 + 하의 1개 + 신발 1개는 기본
- 날씨가 춥거나 바람이 강하면 아우터 후보 포함
- 비 예보 시 waterproof 아이템 우선
- 선택 상황에 맞지 않는 formality 범위는 초기 필터링

### 세부 점수

- `weather_fit`: 체감온도, 강수확률, 바람, 레이어링 가능성
- `context_fit`: style_tags, formality_score, waterproof/functional 속성
- `color_harmony`: neutral base, monochrome, analogous 보너스 / 충돌 감점
- `user_preference`: 선호 태그와 색상 매칭
- `trend_match`: style_tags와 trend keyword 매칭 평균
- `closet_completeness`: top/bottom/shoes 충족 + outer 필요 시 포함
- `recent_wear_penalty`: 최근 7일 아이템, 최근 3일 동일 조합 감점

### 실패 내성

- 날씨 실패 시 계절/최근 기온 캐시 fallback
- 트렌드 실패 시 0점 처리, 추천은 계속 수행
- 이미지 분석 confidence 낮으면 수동 수정 유도

## 8. 코디 카드 UI 설계

### 카드 구조

- 상단: 날씨 배지, 상황 태그, 제목
- 중단: 상의/하의/아우터/신발 실제 이미지 고정 위치 배치
- 하단: 아이템 이름, 추천 이유 요약 2~3줄, 총점

### 레이아웃 원칙

- 사람 합성 이미지 미사용
- 실제 의류 이미지 썸네일 조합
- 카테고리별 slot 고정
- 요약 정보 우선, 상세 점수는 바텀시트

## 9. 핵심 코드 초안

핵심 코드는 `app/lib` 아래에 포함.

### 추가된 연동 준비 계층

- `AppEnv`: `dart-define` 기반 키 관리
- `OpenWeatherApiService`: 실제 날씨 API 어댑터
- `OpenAiClothingAnalysisService`: 의류 이미지/링크 분석 어댑터
- `FallbackWeatherRepository`: remote 실패 시 mock fallback
- `FallbackTrendRepositoryImpl`: remote 실패 시 mock fallback
- `SupabaseClosetDataSource`: `clothing_items` 저장/조회 골격

## 10. mock 데이터 기반 실행 코드

- mock closet
- mock weather
- mock trend
- mock wear history
- mock user preferences

이 조합만으로 홈 화면이 동작한다.

## 현재 구현된 화면

- 추천 탭: 상황 선택, 추천 카드 3개, 점수 breakdown, 피드백 저장
- 옷장 탭: 카테고리/색상 필터, 상세 바텀시트, 동기화 상태 표시
- 등록 탭: 이미지 선택, 링크/수동 카테고리 입력, AI 분석, 저장

## 화면별 요구사항

세부 화면 요구사항은 [screen_requirements.md](/Users/hyunjessieyang/Documents/Playground/docs/screen_requirements.md) 참고.

### 홈

- 오늘 날씨 요약
- 상황 선택
- 추천 코디 3개
- 추천 이유
- 빠른 액션

### 옷장

- 빠른 등록
- 필터/정렬
- 아이템 수정
- 분석 상태 표시

### 아이템 상세

- 태그 수정
- 착용 기록
- 이 옷으로 코디 추천

### 기록

- 오늘 입은 옷
- 최근 추천 내역
- 피드백 내역

### 설정

- 위치
- 알림
- 스타일 선호
- 추천 강도

## 실제 기능 / UI 요구사항

### 기능 요구사항

- 사진 업로드 또는 링크 입력으로 옷 아이템 등록
- 카테고리, 색상, 계절, 보온성, 포멀도 추출
- 추천 전 상황 선택
- 현재 날씨, 체감온도, 강수확률, 바람, 최근 착용 기록 반영
- 서로 충분히 구분되는 추천 코디 3개 제공
- 각 추천에 대한 자연어 설명
- 좋아요 / 별로예요 / 오늘 입었어요 피드백
- 특정 아이템 중심 코디 추천

### UI/UX 요구사항

- 앱 진입 직후 오늘 날씨와 추천 코디 우선 노출
- 한 손 조작이 쉬운 상황 선택 칩
- 코디 카드에 이미지, 날씨 요약, 상황 태그, 추천 이유, 액션 버튼 포함
- 등록 플로우는 3단계 이내
- 추천 불가 시 원인과 대안 안내
- 피드백은 최소 클릭 수로 입력

## 남은 실제 연동 TODO

- OpenAI 응답 JSON 강제 모드 안정화
- 트렌드 remote source 구현
- 위치 권한/실기기 현재 좌표 연동
- 사용자 피드백 영속화

## Supabase 운영 정책

- 테이블 RLS와 Storage 정책은 [supabase_policies.sql](/Users/hyunjessieyang/Documents/Playground/docs/supabase_policies.sql)에 분리
- MVP는 익명 로그인 + 사용자별 prefix 업로드 정책 사용
- Storage 경로는 `auth.uid()/timestamp.ext` 형식
- 운영 기본값은 private bucket + signed URL
