# iOS TestFlight Deployment Guide

## 1. 사전 준비

- Xcode 전체 설치
- Apple Developer Program 가입
- App Store Connect에 앱 생성
- Supabase 프로젝트에 [schema.sql](/Users/hyunjessieyang/Documents/Playground/docs/schema.sql) 적용
- Supabase 프로젝트에 [supabase_policies.sql](/Users/hyunjessieyang/Documents/Playground/docs/supabase_policies.sql) 적용
- `clothing-images` private bucket 확인

## 2. 로컬 환경 설정

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
brew install cocoapods
```

프로젝트 이동:

```bash
cd /Users/hyunjessieyang/Documents/Playground/app
```

패키지 설치:

```bash
/Users/hyunjessieyang/Documents/Playground/flutter/bin/flutter pub get
```

## 3. iOS 식별자 설정

수정 파일:

- [/Users/hyunjessieyang/Documents/Playground/app/ios/Runner.xcodeproj/project.pbxproj](/Users/hyunjessieyang/Documents/Playground/app/ios/Runner.xcodeproj/project.pbxproj)
- [/Users/hyunjessieyang/Documents/Playground/app/ios/Runner/Info.plist](/Users/hyunjessieyang/Documents/Playground/app/ios/Runner/Info.plist)

설정 항목:

- Bundle Identifier 예: `com.yourteam.smartcloset`
- Display Name
- Version / Build Number
- Team Signing

## 4. 런타임 키 주입

개발 빌드 예시:

```bash
/Users/hyunjessieyang/Documents/Playground/flutter/bin/flutter run -d ios \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=OPENWEATHER_API_KEY=your-openweather-key \
  --dart-define=OPENAI_API_KEY=your-openai-key
```

릴리스 아카이브 전 빌드 확인:

```bash
/Users/hyunjessieyang/Documents/Playground/flutter/bin/flutter build ios --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=OPENWEATHER_API_KEY=your-openweather-key \
  --dart-define=OPENAI_API_KEY=your-openai-key
```

## 5. TestFlight 업로드

1. `open ios/Runner.xcworkspace`
2. Xcode에서 Signing 설정 확인
3. `Any iOS Device` 선택
4. `Product > Archive`
5. Organizer에서 `Distribute App`
6. `App Store Connect > Upload`
7. 업로드 완료 후 App Store Connect에서 TestFlight 빌드 처리 대기

## 6. 테스트 시나리오

- 익명 로그인 성공
- 추천 카드 3개 렌더링
- 상황 칩 변경 시 추천 재계산
- 이미지 선택 후 AI 분석 성공
- Supabase Storage 업로드 성공
- private bucket signed URL 이미지 표시
- 피드백 저장 후 로컬 상태 반영

## 7. 자주 막히는 지점

- CocoaPods 미설치
- Signing Team 미설정
- Anonymous auth 비활성화
- `clothing-images` bucket 미생성
- iOS 실제 기기에서 사진 권한 문구 누락
