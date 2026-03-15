# Web Static Deployment

개인용으로 계속 같은 주소에서 쓰려면 `trycloudflare` 대신 고정 호스팅 URL이 필요합니다. 현재 구조에서는 Netlify가 가장 단순합니다.

## 권장: Netlify

### 1. 저장소 연결

1. Netlify 가입
2. `Add new site` -> `Import an existing project`
3. GitHub 저장소 연결
4. 프로젝트 루트는 `/Users/hyunjessieyang/Documents/Playground`에 대응하는 저장소 루트

### 2. Build 설정

- Base directory: 비워두기
- Build command: `cd app && flutter build web --release --pwa-strategy=none --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY --dart-define=OPENWEATHER_API_KEY=$OPENWEATHER_API_KEY --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY`
- Publish directory: `app/build/web`

같은 내용이 [netlify.toml](/Users/hyunjessieyang/Documents/Playground/app/netlify.toml)에 들어 있습니다.

### 3. Environment variables

Netlify Site settings -> Environment variables 에 아래 4개 추가:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `OPENWEATHER_API_KEY`
- `OPENAI_API_KEY`

중요:
- `SUPABASE_SERVICE_ROLE_KEY`는 넣지 않습니다
- `OPENAI_API_KEY`는 웹 번들에 들어가므로 운영용으로는 서버 프록시 전환이 더 안전합니다

### 4. 고정 URL

배포가 끝나면 `https://your-site.netlify.app` 형태의 고정 URL이 생깁니다.

이 주소를 쓰면:
- 매번 주소가 바뀌지 않음
- 브라우저가 같은 origin으로 인식
- 자동 익명 로그인/세션 유지가 훨씬 안정적

## 대안: Vercel

Vercel도 가능하지만 Flutter 웹은 빌드 환경을 직접 맞춰야 해서 Netlify보다 조금 번거롭습니다.

기본 설정 파일:
- [vercel.json](/Users/hyunjessieyang/Documents/Playground/app/vercel.json)

권장 흐름:
1. GitHub 저장소 연결
2. Install command 없이 진행
3. Build command를 직접 설정
4. Flutter SDK 세팅이 가능한 경우에만 사용

## 권장 운영 순서

1. Netlify에 먼저 배포
2. 고정 URL에서 앱 확인
3. 그 뒤 Google 로그인 또는 이메일 로그인 재정비
4. 필요하면 커스텀 도메인 연결
