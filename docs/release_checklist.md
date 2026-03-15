# Release Checklist

## 환경

- Supabase URL/Anon Key 준비
- OpenWeather API key 준비
- OpenAI API key 준비
- Anonymous sign-in 활성화
- `clothing-images` private bucket 생성

## 데이터베이스

- [schema.sql](/Users/hyunjessieyang/Documents/Playground/docs/schema.sql) 적용
- [supabase_policies.sql](/Users/hyunjessieyang/Documents/Playground/docs/supabase_policies.sql) 적용
- `users`, `user_preferences`, `clothing_items`, `outfit_feedback` 쓰기 확인

## 앱 검증

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- 최소 1회 실기기 로그인
- 최소 1회 이미지 업로드
- 최소 1회 추천 피드백 저장

## iOS

- Bundle Identifier 설정
- Signing Team 설정
- Photo Library usage description 확인
- Archive 생성
- TestFlight 업로드

## Android

- applicationId 설정
- signingConfig 설정
- AAB 생성
- Internal testing 업로드

## 운영 전 확인

- signed URL 만료 시간 정책 확인
- Supabase 비용/용량 모니터링 확인
- 로그 수집 전략 정의
- 장애 시 fallback 동작 확인
