# JamJam App - Claude 작업 지침

## 핵심 레퍼런스: Vampr (Watch & Connect)

### Watch 기능
- 다른 뮤지션 프로필/활동을 단방향 팔로우 (SNS 팔로우 개념)
- 피드에서 팔로우한 뮤지션의 업데이트 확인
- 팔로우해도 상대방 수락 불필요 (비대칭 관계)
- 뮤지션의 새 트랙 업로드, 공연 일정, 활동 내역 노출

### Connect 기능
- 스와이프 기반 뮤지션 매칭 (Tinder 방식)
- 서로 Like하면 연결 성사 (대칭 관계)
- 연결 성사 후 채팅 가능
- 장르, 악기, 위치 기반 추천 필터


## 협업 규칙 (반드시 준수)

1. **많은 부분을 수정해야 한다면 반드시 먼저 물어보고 진행한다.**
2. **하나의 파일에 코드 다 넣지 말고, 기능별로 모듈화한다.**
3. **요청이 명확하지 않을 때 추론 및 실행하지 말고, 우선 내 설명을 제대로 이해했는지 먼저 말한다.**

---

## 컨텍스트 관리 규칙

- 작업 완료 시마다 아래 체크리스트를 업데이트한다.
- 새 세션 시작 시 이 파일을 먼저 읽고 현재 상태를 파악한다.
- 컨텍스트가 많이 쌓였다고 판단되면 `/compact` 실행 후 이 파일 업데이트를 제안한다.

---

## 전체 목표

Supabase 백엔드 연동 완성 + PPG(파워퍼프걸) 스타일 UI 리디자인.

`flutter analyze --no-pub` → **항상 No issues found! 유지**

---

## 현재 상태: Phase A~F 진행 중

브랜치: `feat/supabase-bridge` | 최근 커밋: (이번 커밋)

### Phase F — PPG UI 리디자인 + 네비게이션 구조 개편 🚧

| 단계 | 상태 | 내용 |
|------|------|------|
| F-1 app_theme.dart | ✅ 완료 | PPG 라이트 테마 전환 — cream(`#FFFEF5`) 배경, hot pink(`#FF5CA8`), 두꺼운 아웃라인, 하위호환 컬러 앨리어스 유지 |
| F-2 main_screen.dart | ✅ 완료 | 탭 5개 → 3개 (홈·검색·프로필), Jam/친구/채팅 탭 제거, 상단 2px 검정 보더 |
| F-3 home_tab.dart | ✅ 완료 | Connect 서브탭 내장 — PPG pill 탭바(피드\|Connect) + `TabController` + `_ConnectSubTab` + FAB 조건부 노출 |

### Phase F 중요 메모
- `app_theme.dart` 하위호환: `primaryBlack`=크림, `secondaryBlack`=흰색카드, `white`=다크텍스트 (기존 위젯 수정 불필요)
- `_ConnectSubTab`: Scaffold 없이 `home_tab.dart` 하단에 private 클래스로 임베드, ConnectService 로직 그대로 복제
- FAB: `ListenableBuilder(_tabController)` → 피드 탭(index=0)에서만 노출
- `_buildSubTabBar()`: `lightGrey` 배경 + `outlineBlack` 2px 보더 + `accentPink` 인디케이터 pill 모양
- `TabBarView(physics: NeverScrollableScrollPhysics)` — 스와이프 전환 비활성화

### 다음 작업 후보 (Phase G)
- [ ] `my_music_screen` 업로드 다이얼로그 실제 구현 (현재 placeholder)
- [ ] Supabase `media` 버킷 생성 확인 및 public 권한 설정
- [ ] `uploadMedia()` 확장자 하드코딩 개선 (실제 파일 MIME 타입 기반)
- [ ] 홈 피드 → 프로필 탭 "내 음악" 크로스 탭 데이터 일관성 검증
- [ ] 나머지 위젯 PPG 스타일 세부 다듬기 (카드 보더, 버튼 형태 등)

---

### Phase E — 버그 수정 및 미디어 업로드 개선 ✅

| 단계 | 상태 | 내용 |
|------|------|------|
| E-1 feed_service.dart | ✅ 완료 | `createFeed()` 미디어 업로드 try/catch 분리 |
| E-2 jam_creation_tab.dart | ✅ 완료 | `StatefulBuilder` + `_modalSetState` 패턴으로 모달 내 미리보기 즉시 반영 |
| E-3 media_file_picker_web.dart | ✅ 완료 | 브라우저 native `<input type="file">` 기반 파일 피커 |
| E-4 video_blob_helper_web.dart | ✅ 완료 | 웹에서 Uint8List → Blob URL 변환 유틸 |
| E-5 app_theme.dart | ✅ 완료 | (F-1에서 PPG 테마로 교체됨) |

### Phase E 중요 메모
- `feed_service.createFeed()`: 미디어 업로드 실패 → `resolvedUrl = null` 폴백, 피드 insert는 반드시 실행
- `media` Supabase Storage 버킷이 없으면 업로드 실패 → 피드는 미디어 URL 없이 저장됨 (정상 폴백)
- 미디어 확장자는 `uploadMedia()`에서 하드코딩(mp3/mp4/jpg) — 실제 파일 타입과 다를 수 있음

---

### Phase C/D 진행 현황

| 단계 | 상태 | 내용 |
|------|------|------|
| C-1 SQL migration | ✅ 완료 | `supabase/migrations/003_phase_c_likes_bookmarks.sql` 실행 완료 (사용자 진행) |
| C-2 like_service.dart | ✅ 완료 | `LikeService` 신규 생성 (`getLikedFeeds`, `like`, `unlike`, `isLiked`) |
| C-3 supabase_service.dart | ✅ 완료 | `getLikedFeeds`, `likeFeed`, `unlikeFeed`, `isFeedLiked` 4개 메서드 추가 |
| C-4 liked_content_screen.dart + home_tab.dart | ✅ 완료 | 좋아요 화면 Supabase 연동, `_toggleLike` LikeService 연동 |
| C-5 search_tab.dart | ✅ 완료 | `searchProfiles()` 연동, `_mapProfileToMusician` 헬퍼 추가 |
| C-6 profile_tab.dart | ✅ 완료 | 팔로워/팔로잉 카운트 실시간 로드 (`FollowService.getCounts`) |
| D-1 my_music_screen.dart | ✅ 완료 | `FeedService.getMyFeeds()` + `supabase_service.getMyFeeds()` 연동 |
| D-2 recommendation_service.dart | ✅ 완료 | 하드코딩 제거, `ConnectService.getCandidates()` 연동 |
| D-3 commit + PR | ✅ 완료 | |

### Phase C/D 중요 메모
- `LikeService`: `feed_likes` 테이블, UUID 문자열 feedId 사용
- `home_tab._toggleLike`: `supabaseId` 있으면 LikeService, 없으면 CounterService 폴백
- `search_tab._executeAdvancedSearch`: 쿼리 비어있으면 로컬 검색, 있으면 Supabase `searchProfiles()`
- `profile_tab`: `_loadStats()` → `FollowService.getCounts(userId)` → `_followerCount`/`_followingCount`
- `my_music_screen`: feeds → music card 포맷 변환 (`_feedToMusic`), supabaseId 있을 때만 실제 삭제
- `recommendation_service`: 스코어링 로직 제거, ConnectService 후보를 최대 limit개 반환

### Phase B 진행 현황

| 단계 | 상태 | 내용 |
|------|------|------|
| B-1-1 supabase_service.dart | ✅ 완료 | follow 관련 7개 raw 메서드 추가 |
| B-1-2 follow_service.dart | ✅ 완료 | `FollowService` 신규 생성 (singleton, `lib/core/services/`) |
| B-1-3 user_profile_screen.dart | ✅ 완료 | `userId` 파라미터, FollowService 연동, 팔로우 버튼 로딩 상태 |
| B-1-4 friends_screen.dart | ✅ 완료 | 친구 탭 Supabase 팔로잉 목록 연동 |
| B-1-5 home_tab.dart | ✅ 완료 | `전체\|팔로잉` 피드 모드 토글 + `_fetchFollowingFeeds()` |
| B-2-1 supabase_service.dart | ✅ 완료 | connect_likes/matches raw 메서드 6개 추가 (`likeUser`, `unlikeUser`, `hasLiked`, `checkMutualLike`, `createMatch`, `getMatches`, `getCandidates`) |
| B-2-2 connect_service.dart | ✅ 완료 | `ConnectService` 신규 생성 (`getCandidates`, `like`, `pass`, `getMatches`) |
| B-2-3 musician_card_widget.dart | ✅ 완료 | 스와이프 카드 UI (`lib/features/home/.../shared/`) |
| B-2-4 connect_screen.dart | ✅ 완료 | Connect 스와이프 화면 (`lib/features/home/.../screens/`) |
| B-2-5 friends_screen.dart | ✅ 완료 | '추천' 탭 → '매칭' 탭 (ConnectService 매칭 목록 + ConnectScreen 진입 버튼) |
| B-3-1 supabase_service.dart | ✅ 완료 | notifications raw 메서드 5개 추가 (`getNotifications`, `getUnreadNotificationCount`, `markNotificationRead`, `markAllNotificationsRead`, `subscribeToNotifications`) |
| B-3-2 notification_service.dart | ✅ 완료 | `NotificationService` 신규 생성 (`lib/core/services/`) |
| B-3-3 notification_tile.dart | ✅ 완료 | 알림 타일 위젯 (`lib/features/home/.../shared/`) |
| B-3-4 notifications_screen.dart | ✅ 완료 | 알림 화면 — 전체/안읽음 탭 + 실시간 구독 (`lib/features/home/.../screens/`) |
| B-3-5 home_tab.dart | ✅ 완료 | 벨 아이콘 → NotificationsScreen 연결 + 뱃지 표시 |

### Phase B 중요 메모
- `AuthStateManager`에 `userId` getter 없음 → UUID는 항상 `SupabaseService.instance.currentUser?.id` 사용
- `feed_service.dart` `_mapRow`에 `'authorId': row['user_id']` 추가됨 (팔로잉 피드 필터용)
- 팔로잉 모드는 최대 50개 fetch 후 로컬 필터, 페이지네이션 없음
- DB 스키마: `supabase/migrations/002_phase_b_social.sql` 실행 완료 (follows, connect_likes, matches, notifications)

---

### Phase A 진행 현황

| 단계 | 상태 | 내용 |
|------|------|------|
| A-1 DB 스키마 | ✅ 완료 | `supabase/migrations/001_schema_setup.sql` 실행 완료, `.env` dotenv 전환 완료 |
| A-2 Auth 연동 | ✅ 완료 | `onAuthStateChange` 리스너, `signUpWithProfile()`, `signup_modal.dart` 단일 호출 전환, `main.dart` dotenv 중복 제거 |
| A-3 Profiles | ✅ 완료 | Supabase `profiles` 테이블 읽기/쓰기, `avatars/` Storage 업로드, `avatar_url` 동기화 |
| A-4 Feeds | ✅ 완료 | `FeedService` + `home_tab.dart` 5개 메서드 연동, 페이지네이션 offset 방식 |
| A-5 Comments | ✅ 완료 | `CommentService.loadFromSupabase()` + ID 매핑 사전, `comment_modal.dart` `supabaseFeedId` 파라미터 + async init |
| A-6 Jam Sessions | ✅ 완료 | `JamService` 신규 생성, `jam_creation_tab.dart` Supabase fetch/create 연동 |
| A-7 Chat | ✅ 완료 | `ChatService` 신규 생성, `supabase_service.dart` 6개 메서드 추가, `chat_tab.dart` 대화 목록 로드, `chat_room_screen.dart` 실시간 구독 연동 |
| A-8 미디어 업로드 | ✅ 완료 | `supabase_service.dart` `uploadMedia()` 추가, `feed_service.dart` Storage 업로드 후 URL 저장, `home_tab.dart` `mediaData` 전달 |

### A-3 완료된 것
- `supabase_service.dart`: `uploadAvatar(userId, imageBytes)` 추가 (upsert, `avatars/{userId}.jpg`)
- `auth_state_manager.dart`: `_avatarUrl` 필드+getter, `_loadProfileFromSupabase()` (비동기 논블로킹), `updateAvatarUrl()`, `saveProfileData()`에 Supabase upsert 연동
- `profile_image_manager.dart`: `saveProfileImage()` 내 Supabase Storage 업로드 + `avatar_url` 저장 (논블로킹)
- `profile_tab.dart`: `CircleAvatar`에 `NetworkImage` 폴백 추가 (로컬 bytes 없을 때 CDN URL 사용)

### 중요 스키마 메모
- `feeds` 테이블: `user_id` (author_id 아님)
- `jam_sessions` 테이블: `creator_id` (host_id 아님)
- `profiles` 테이블: `id, username, nickname, bio, instruments, avatar_url, created_at`
- Supabase URL: `https://mwllqreadynmaoorymkn.supabase.co` (.env에서 로드)

---

## 이전 완료 로그

### flutter analyze 클린업 ✅ (Phase 0)

| 파일 | 처리 내용 |
|------|-----------|
| `chat_room_screen.dart` | import 경로 수정 |
| `bookmarks_screen.dart` | import 경로 수정 |
| `friends_screen.dart` | import 경로 수정 |
| `liked_content_screen.dart` | import 경로 수정 |
| `user_profile_screen.dart` | import 경로 수정 |
| `chat_tab.dart` | import 경로 수정 |
| `profile_tab.dart` | import 경로 수정 |
| `app_state_manager.dart` | 미사용 import 제거 |
| `comment_service.dart` | 미사용 import 제거 |
| `counter_service.dart` | 미사용 import 제거 |
| `profile_image_manager.dart` | 미사용 import 제거 |
| `supabase_service.dart` | 미사용 로컬 변수 제거 |
| `feed_edit_modal.dart` | write-only 필드 제거 |
| `profile_edit_modal.dart` | write-only 필드 제거 |
| `report_modal.dart` | 미사용 메서드 제거 |
| `live_streaming_screen.dart` | write-only 필드 제거 |
| `home_tab.dart` | 미사용 import/필드/메서드 제거 |
| `jam_creation_tab.dart` | write-only 필드 3개 + 미사용 메서드 8개 + 관련 import 제거 |
| `profile_tab.dart` | write-only 필드 4개(`_userName` 등) + 관련 setState 블록 제거 |
| `search_tab.dart` | write-only 필드 3개 + 미사용 메서드 3개(`_loadSearchHistory` 포함) + 호출부 제거 |
