# 매일퀴즈 (MaeilQuiz)

매일 새로운 퀴즈로 지식을 키우는 모바일 앱

6가지 카테고리(IT, 경제, 역사, 심리, 시사, 과학)에서 매일 20문제씩 퀴즈를 풀고, 해설을 통해 학습할 수 있습니다.

## 주요 기능

- **카테고리별 퀴즈** — IT, 경제, 역사, 심리, 시사, 과학 6개 분야
- **세로 스와이프 피드** — 숏폼 스타일의 세로 PageView로 퀴즈 탐색
- **즉시 피드백** — 정답/오답 표시 + 상세 해설 제공
- **일일 제한** — 무료 사용자 하루 20문제, 자정 자동 리셋
- **무한 스크롤** — 커서 기반 페이지네이션으로 끊김 없는 퀴즈 로딩
- **익명 사용자** — UUID 기반 식별, 별도 회원가입 불필요

## 기술 스택

| 영역 | 기술 |
|------|------|
| Framework | Flutter 3.3+ / Dart 3.x |
| 상태 관리 | Riverpod (AsyncNotifier) |
| 라우팅 | GoRouter |
| 백엔드 | Supabase (PostgreSQL + RPC Functions) |
| 로컬 저장 | SharedPreferences |
| 광고 | Google Mobile Ads (배너 + 전면) |
| ID 생성 | UUID v4 |

## 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점 (Supabase, AdMob, Riverpod 초기화)
├── core/
│   ├── constants/               # 앱 상수 (카테고리, 일일 한도)
│   └── router/                  # GoRouter 라우팅 설정
├── features/
│   ├── auth/
│   │   ├── splash_screen.dart   # 초기화 (UUID 생성, 유저 등록, daily_count 리셋)
│   │   └── user_repository.dart # 사용자 관리 (등록, 카테고리 업데이트)
│   ├── quiz/
│   │   ├── quiz_feed_screen.dart  # 메인 퀴즈 화면 (세로 PageView)
│   │   ├── quiz_provider.dart     # 퀴즈 상태 관리 (Riverpod AsyncNotifier)
│   │   ├── quiz_repository.dart   # Supabase RPC 호출
│   │   └── models/                # Question, AnswerResult 모델
│   ├── settings/
│   │   ├── settings_screen.dart   # 구독 상태, 남은 퀴즈 수
│   │   └── category_screen.dart   # 카테고리 선택 (그리드 UI)
│   └── payment/                   # 프리미엄 결제 (미구현)
└── shared/
    ├── widgets/                   # 배너 광고, 전면 광고
    └── theme/                     # Material 3 테마 (보라색 #6B21A8)
```

## Supabase 백엔드

### 테이블

| 테이블 | 설명 |
|--------|------|
| `users` | android_id(UUID), categories(jsonb), daily_count, is_premium |
| `questions` | content, option_1~4, answer(1-based), explanation, category, is_active |
| `user_history` | user_id, question_id, is_correct, answered_at (30일 기준 필터) |

### RPC Functions (SECURITY DEFINER)

| 함수 | 설명 |
|------|------|
| `upsert_user` | 사용자 등록/조회 |
| `get_quiz_feed` | 카테고리별 미풀이 퀴즈 조회 (daily_count < 20, 30일 내 히스토리 제외) |
| `get_user_info` | 사용자 정보 조회 (categories, daily_count, is_premium) |
| `submit_quiz_answer` | 답변 기록 + daily_count 증가 |
| `reset_daily_count` | 자정 기준 일일 카운트 리셋 |
| `update_categories` | 카테고리 변경 |

## 환경변수

`.env` 파일에 다음 값을 설정합니다:

```
SUPABASE_URL=
SUPABASE_ANON_KEY=
ADMOB_BANNER_ID=
ADMOB_INTERSTITIAL_ID=
```

## 빌드 및 배포

```bash
# 개발 실행
flutter run --dart-define-from-file=.env

# 릴리즈 번들 (Google Play)
flutter build appbundle --dart-define-from-file=.env
```

릴리즈 빌드 시 `android/key.properties`에 키스토어 설정이 필요합니다.

## 광고 정책

- 하단 배너 광고: 퀴즈 화면에 고정 노출
- 전면 광고: 15문제마다 1회 노출
