# Android Internal Testing Deployment Guide

## 1. 사전 준비

- Android Studio 설치
- Android SDK / Platform Tools / Build Tools 설치
- Play Console 앱 생성
- Supabase에 [schema.sql](/Users/hyunjessieyang/Documents/Playground/docs/schema.sql) 적용
- Supabase에 [supabase_policies.sql](/Users/hyunjessieyang/Documents/Playground/docs/supabase_policies.sql) 적용

## 2. Android SDK 연결

```bash
/Users/hyunjessieyang/Documents/Playground/flutter/bin/flutter config --android-sdk <ANDROID_SDK_PATH>
/Users/hyunjessieyang/Documents/Playground/flutter/bin/flutter doctor -v
```

## 3. 앱 식별자 설정

수정 파일:

- [/Users/hyunjessieyang/Documents/Playground/app/android/app/build.gradle.kts](/Users/hyunjessieyang/Documents/Playground/app/android/app/build.gradle.kts)
- [/Users/hyunjessieyang/Documents/Playground/app/android/app/src/main/AndroidManifest.xml](/Users/hyunjessieyang/Documents/Playground/app/android/app/src/main/AndroidManifest.xml)
- [/Users/hyunjessieyang/Documents/Playground/app/android/app/src/main/kotlin/com/example/smart_closet/MainActivity.kt](/Users/hyunjessieyang/Documents/Playground/app/android/app/src/main/kotlin/com/example/smart_closet/MainActivity.kt)

설정 항목:

- applicationId 예: `com.yourteam.smartcloset`
- 앱 이름
- versionCode / versionName
- 서명 키 설정

## 4. 로컬 실행

```bash
cd /Users/hyunjessieyang/Documents/Playground/app
/Users/hyunjessieyang/Documents/Playground/flutter/bin/flutter run -d android \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=OPENWEATHER_API_KEY=your-openweather-key \
  --dart-define=OPENAI_API_KEY=your-openai-key
```

## 5. AAB 빌드

릴리스 키스토어 준비 후 `android/key.properties`와 signingConfig 연결이 필요하다.

빌드 명령:

```bash
/Users/hyunjessieyang/Documents/Playground/flutter/bin/flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=OPENWEATHER_API_KEY=your-openweather-key \
  --dart-define=OPENAI_API_KEY=your-openai-key
```

산출물:

- [/Users/hyunjessieyang/Documents/Playground/app/build/app/outputs/bundle/release/app-release.aab](/Users/hyunjessieyang/Documents/Playground/app/build/app/outputs/bundle/release/app-release.aab)

## 6. Play Console 내부 테스트 업로드

1. Play Console > Testing > Internal testing
2. 새 릴리스 생성
3. `app-release.aab` 업로드
4. 릴리스 노트 입력
5. 테스터 그룹 지정
6. 롤아웃

## 7. 테스트 시나리오

- 앱 첫 실행 시 익명 로그인
- 네트워크 정상/오류 fallback
- 이미지 업로드 후 signed URL 표시
- 추천 카드 렌더링 성능 확인
- Android 사진 선택 권한 및 gallery picker 확인

## 8. 자주 막히는 지점

- SDK 경로 미설정
- Release signing 미설정
- `applicationId`와 패키지 경로 불일치
- Play Console 최소 SDK/타깃 SDK 정책 미반영
