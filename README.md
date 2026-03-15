# Smart Closet

Flutter + Riverpod + Supabase 기반의 개인 옷장/날씨/상황형 코디 추천 앱 설계 및 최소 실행 버전입니다.

## 포함 범위

- 요구사항 정리와 MVP 범위 정의
- 전체 시스템 아키텍처 문서
- Postgres/Supabase 스키마 SQL
- Flutter feature-first 구조
- mock 데이터 기반 추천 엔진
- 코디 카드 UI
- 오늘의 추천 화면
- 테스트 예시

## 실행

1. Flutter SDK 설치
2. `cd /Users/hyunjessieyang/Documents/Playground/app`
3. `flutter pub get`
4. 필요 시 `.env.example` 값을 기준으로 `--dart-define` 전달
5. `flutter run`

예시:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=OPENWEATHER_API_KEY=your-openweather-key \
  --dart-define=OPENAI_API_KEY=your-openai-key
```

초기 버전은 mock 데이터로 동작하며 외부 API 연동은 `TODO` 로 분리했습니다.

## 현재 연동 상태

- 인증: Supabase 익명 로그인 + mock fallback
- 스토리지: Supabase Storage `clothing-images` 업로드 + mock fallback
- 날씨: OpenWeather remote repository + mock fallback
- 트렌드: remote placeholder + mock fallback
- 의류 분석: OpenAI Vision-style request service + mock fallback
- 의류 저장: Supabase `clothing_items` insert 골격 포함
- UI 흐름: 추천 탭 / 옷장 탭 / 등록 탭 구현
- mock 저장: 등록 완료 시 로컬 옷장 상태에 즉시 반영

## Storage 준비

Supabase에 아래 버킷이 필요합니다.

- bucket name: `clothing-images`
- private bucket 권장
- 앱은 signed URL 방식으로 이미지 조회

## Supabase 배포 순서

1. Supabase 프로젝트 생성
2. Authentication에서 Anonymous sign-ins 활성화
3. SQL Editor에서 [schema.sql](/Users/hyunjessieyang/Documents/Playground/docs/schema.sql) 실행
4. SQL Editor에서 [supabase_policies.sql](/Users/hyunjessieyang/Documents/Playground/docs/supabase_policies.sql) 실행
5. Storage에 `clothing-images` 버킷 존재 확인
6. 앱 실행 시 `SUPABASE_URL`, `SUPABASE_ANON_KEY` 전달

## 운영 체크리스트

- 익명 로그인 허용 여부 검토
- signed URL 만료 시간 정책 검토
- 버킷은 private 유지
- `trend_signals`는 서버 측 배치 또는 Edge Function으로 적재
- OpenWeather/OpenAI 키는 앱 번들 하드코딩 금지

## 배포 가이드

- iOS TestFlight: [deploy_ios_testflight.md](/Users/hyunjessieyang/Documents/Playground/docs/deploy_ios_testflight.md)
- Android Internal Testing: [deploy_android_play.md](/Users/hyunjessieyang/Documents/Playground/docs/deploy_android_play.md)
- 공통 릴리스 체크리스트: [release_checklist.md](/Users/hyunjessieyang/Documents/Playground/docs/release_checklist.md)
- 화면/기능 요구사항: [screen_requirements.md](/Users/hyunjessieyang/Documents/Playground/docs/screen_requirements.md)
- 트렌드 적재 파이프라인: [trend_pipeline.md](/Users/hyunjessieyang/Documents/Playground/docs/trend_pipeline.md)
- 트렌드 seed SQL: [trend_seed.sql](/Users/hyunjessieyang/Documents/Playground/docs/trend_seed.sql)
- 트렌드 cron SQL: [trend_cron.sql](/Users/hyunjessieyang/Documents/Playground/docs/trend_cron.sql)
- 트렌드 함수 배포 가이드: [trend_function_deploy.md](/Users/hyunjessieyang/Documents/Playground/docs/trend_function_deploy.md)
- 웹 고정 배포 가이드: [deploy_web_static.md](/Users/hyunjessieyang/Documents/Playground/docs/deploy_web_static.md)
