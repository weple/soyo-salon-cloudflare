# 소요살롱 · SOYO SALON

모바일 독서모임 웹사이트. 첨부된 Cloudflare Worker + Supabase 프로젝트를 기반으로 개발했습니다.

## 실행 모드

- `public/`: 실제 운영 화면. 카카오 로그인과 `/api/*` Worker API 사용. `config.js`의 `SOYO_PREVIEW=false` 유지.
- `npm run build`: `dist/`에 독립적인 디자인 미리보기 생성. 이 모드만 가상 로그인·관리자 전환·브라우저 저장을 사용합니다.
- `src/index.js`: 실제 서버. 미리보기 관리자 전환은 서버 권한과 아무 관련이 없습니다.
- Sites 주소는 소유자 전용 디자인 미리보기입니다. 실제 회원 모집 주소가 아닙니다.
- 예시 책과 일정은 미리보기에만 사용되며, 운영 DB에 자동 등록되지 않습니다.

## 구현

첨부 원본 스타일의 모바일 UI (파란 히어로, 보라색 버튼, 그라데이션 모임 카드, 둥근 하단 탭) / 하단 탭 / 분야 필터 / 모임 상세 / 무료 신청 확인 / 로그인 후 선택한 모임 복귀 / MY 신청 상태·취소·전체 내역 / 운영자 승인·대기·취소 / 모임 추가·마감·재개.

카카오 OAuth 서버 교환, SHA-256 HMAC HttpOnly 세션, Origin 검증, 요청 크기 제한, 관리자 카카오 ID 허용 목록, 공개 이벤트 API 필드 제한을 적용했습니다. 정원과 신청자 수는 공개 API에 포함하지 않습니다. Supabase 테이블에는 공개 RLS 정책이 없으며 Worker의 서버 키로만 접근합니다.

## 1. Supabase

1. 자신의 Supabase 계정에서 프로젝트를 만듭니다.
2. SQL Editor에서 `schema.sql`을 실행합니다. 기존 테이블과 함수를 유지/갱신하는 스키마입니다. 후기와 서평 테이블 및 표지 칼럼 추가를 위해 변경 후에도 한 번 더 실행해야 합니다.
3. Project URL과 `Secret key`(`sb_secret_...`)를 Worker 비밀값 `SUPABASE_SECRET_KEY`로 저장합니다. 기존 legacy `service_role` 키도 `SUPABASE_SERVICE_ROLE_KEY` 이름으로 호환됩니다. 어느 키든 브라우저 코드에는 입력하지 않습니다.
4. 최초 모임은 Table Editor의 `events` 또는 로그인 후 관리자 화면에서 추가합니다.
5. 카카오 로그인 후 `users.kakao_id`에서 본인의 ID를 확인하여 관리자 허용 목록에 설정합니다.

## 2. Kakao Developers

1. 앱에서 카카오 로그인을 활성화합니다.
2. REST API 키 설정에 `https://운영도메인/auth/callback`을 Redirect URI로 등록합니다.
3. 닉네임 제공 설정을 확인합니다. 이메일이나 전화번호는 요청하지 않습니다.
4. REST API 키와 활성화된 Client Secret을 Worker 비밀값으로 등록합니다.
5. 사용자 취소 시 로그인 화면으로 돌아가고, state가 일치하지 않는 콜백은 거부합니다.

## 3. Cloudflare Workers

Node.js 22 이상 권장. 프로젝트 폴더에서:

```sh
npm install
npx wrangler login
```

`wrangler.jsonc`의 `PUBLIC_ORIGIN`은 운영 도메인(`https://soyo-salon.com`)으로 설정합니다. 끝에 `/`를 붙이지 않습니다. 카카오 개발자 콘솔의 Redirect URI와 동의항목 설정에도 `https://soyo-salon.com/auth/callback`을 등록해야 합니다.

```sh
npx wrangler secret put SUPABASE_URL
npx wrangler secret put SUPABASE_SECRET_KEY
npx wrangler secret put KAKAO_REST_API_KEY
npx wrangler secret put KAKAO_CLIENT_SECRET
npx wrangler secret put SESSION_SECRET
npx wrangler secret put ADMIN_KAKAO_IDS
npm run deploy
```

SESSION_SECRET은 무작위 32바이트 이상으로 생성합니다. 관리자 ID는 쉼표로 구분합니다. 카카오 Client Secret을 비활성화했다면 해당 설정은 생략합니다.

정적 자산은 **public/**에서 배포합니다. 미리보기용 dist/를 운영 배포하지 않습니다. `/api/*`와 `/auth/*`는 Worker 우선 실행하여 SPA 라우팅이 로그인 콜백을 가로채지 않도록 설정했습니다.

## 로컬 개발 및 검증

```sh
npm run check
npm test
npm run build
# 운영 API를 로컬에서 확인하려면 .dev.vars.example을 .dev.vars로 복사하고 설정
npm run dev:worker
```

11개 Node 테스트: 외부 Origin·누락 Origin 차단, 비로그인 신청 차단, 일반 회원 관리자 접근 차단, 변조 세션, 공개 API 필드, 잘못된 JSON, 큰 요청, 정원 입력, 로그아웃, OAuth state 검증.

브라우저에서는 미리보기의 신청 → MY 승인 대기 → 관리자 승인 → MY 참여 확정을 확인했습니다. 실제 카카오 계정, Supabase 트랜잭션, Cloudflare 계정 배포는 아직 실행하지 않았습니다.

## 공개 전 남은 설정

- 실제 모임 날짜·장소 등록 및 카카오/Cloudflare/Supabase 계정 연결.
- 개인정보 안내의 운영자 연락처·보유 기간·삭제 요청 절차 확정. 현재 안내는 초안입니다.
- 실도메인에서 로그인·로그아웃·신청·취소·관리자 승인·중복 신청·정원 동시 요청 시험.
- 실기기 Safari에서 키보드·안전 영역·하단 버튼 확인.

사이트에서는 공개용 닉네임 변경을 지원합니다. 신청 시 입금자명을 선택 입력할 수 있고, Worker의 관리자 전용 신청 조회에서만 표시됩니다. 이 필드를 사용하려면 `migrations/20261109_application_depositor_name.sql`을 Supabase SQL Editor에서 실행합니다.

모임 공유 주소는 `/share/모임이름-짧은코드` 형식이며, 기존 UUID 공유 주소도 계속 열립니다. 공유 코드 칼럼을 준비하려면 `migrations/20261109_event_share_codes.sql`을 Supabase SQL Editor에서 실행합니다.

자동 카카오톡 발송은 아직 연결되지 않았습니다. Kakao Login만으로는 로그인한 회원에게 임의 메시지를 보낼 수 없습니다. 자동 안내에는 카카오톡 채널과 비즈니스 메시지(알림톡) 발송 권한, 승인된 알림톡 템플릿, Solapi 등 공식 발송 대행사 계정/API 자격 증명이 필요합니다. 수신 전화번호와 메시지 수신 동의를 별도로 수집해야 하므로, 연동이 준비되기 전에는 전화번호를 받지 않습니다. 계좌번호도 사이트에 공개하지 않고, 신청을 승인한 뒤 운영자가 안내하는 흐름을 권장합니다.

## 공식 참고

- https://developers.kakao.com/docs/ko/kakaologin/rest-api
- https://developers.cloudflare.com/workers/static-assets/binding/
- https://supabase.com/docs/guides/database/postgres/row-level-security
