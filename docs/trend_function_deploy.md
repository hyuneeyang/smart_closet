# Trend Function Deploy

## 준비

1. Supabase CLI 설치
2. 프로젝트 로그인/링크
3. Edge Function env 설정

## CLI 설치

macOS 예시:

```bash
brew install supabase/tap/supabase
```

## 프로젝트 링크

```bash
cd /Users/hyunjessieyang/Documents/Playground
supabase login
supabase link --project-ref veneblpslwyxojywfbri
```

## env 파일 준비

```bash
cp /Users/hyunjessieyang/Documents/Playground/supabase/.env.functions.example /Users/hyunjessieyang/Documents/Playground/supabase/.env.functions
```

`.env.functions` 에 실제 값을 넣는다.

## 함수 배포

```bash
cd /Users/hyunjessieyang/Documents/Playground
supabase functions deploy trend-signals-sync --no-verify-jwt
```

## 함수 호출 테스트

```bash
curl -X POST \
  'https://veneblpslwyxojywfbri.supabase.co/functions/v1/trend-signals-sync' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_SUPABASE_ANON_KEY' \
  -d '{"region":"KR"}'
```

## 기대 결과

- `trend_signals` 에 `keyword/region/date` 기준 upsert
- 외부 endpoint 실패 시 `internal_dictionary` 기반 데이터라도 적재
- 응답 JSON에 `providerErrors` 포함

## 운영 팁

- `verify_jwt = false` 로 두면 cron/서버 호출이 단순해진다
- 운영 환경에서는 IP allowlist 또는 별도 shared secret 검토
- 외부 공급자는 앱에서 직접 호출하지 말고 Edge Function 뒤로 숨긴다
