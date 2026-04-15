# JamJam Supabase Bridge — 전체 실행 계획

> **목표**: UI 코드는 최소한으로 건드리고, Service 계층 교체로 Supabase 연동 완성  
> **원칙**: `flutter analyze --no-pub` → 항상 **No issues found!** 유지  
> **브랜치**: `feat/supabase-bridge`

---

## 진행 현황 요약

| Phase | 내용 | 상태 |
|-------|------|------|
| A | 기초 연동 (Auth, Profiles, Feeds, Comments, Jam, Chat, Media) | ✅ 완료 |
| B | 소셜 기능 (Follow, Connect/Match, Notifications) | ✅ 완료 |
| C | 사용자 활동 (검색, 북마크, 좋아요 내역, 프로필 통계) | ⬜ 예정 |
| D | 마무리 (내 음악, 추천, 최종 정리 & 배포) | ⬜ 예정 |

---

## Phase C — 사용자 활동 Supabase 연동

**왜 C인가?** 사용자가 앱을 껐다 켜도 북마크·좋아요·검색 결과가 유지되어야 한다.  
현재는 전부 하드코딩 mock이라 재시작 시 데이터가 사라진다.

### C-1: DB 마이그레이션 (`003_phase_c_activity.sql`)

새로 필요한 테이블:

```sql
-- 북마크 (피드 저장)
CREATE TABLE bookmarks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  feed_id uuid REFERENCES feeds(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE (user_id, feed_id)
);

-- 피드 좋아요 (누가 어떤 피드를 좋아했는지 추적)
CREATE TABLE feed_likes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  feed_id uuid REFERENCES feeds(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE (user_id, feed_id)
);

-- RLS 활성화
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE feed_likes ENABLE ROW LEVEL SECURITY;

-- 정책: 본인 행만 읽기/쓰기
CREATE POLICY "bookmarks_own" ON bookmarks USING (auth.uid() = user_id);
CREATE POLICY "feed_likes_own" ON feed_likes USING (auth.uid() = user_id);
```

> ⚠️ **수동 실행 필요**: Supabase 대시보드 SQL Editor에서 실행

---

### C-2: `supabase_service.dart` — raw 메서드 추가

추가할 메서드 (파일 끝 `// C-2` 섹션):

| 메서드 | 설명 |
|--------|------|
| `bookmarkFeed(feedId)` | 북마크 추가 (upsert) |
| `unbookmarkFeed(feedId)` | 북마크 제거 |
| `isBookmarked(feedId)` | 북마크 여부 확인 |
| `getBookmarkedFeeds()` | 내 북마크 목록 (feeds join) |
| `likeFeed(feedId)` | 피드 좋아요 + feeds.likes_count++ |
| `unlikeFeed(feedId)` | 피드 좋아요 취소 + likes_count-- |
| `getLikedFeeds()` | 내가 좋아한 피드 목록 (feeds join) |
| `getFollowerCount(userId)` | 팔로워 수 |
| `getFollowingCount(userId)` | 팔로잉 수 |
| `searchProfiles(query)` | profiles 테이블 ilike 검색 |

---

### C-3: `bookmark_service.dart` 신규 + `bookmarks_screen.dart` 연동

- `lib/core/services/bookmark_service.dart` 신규 생성
  - `getBookmarkedFeeds()` → `_mapFeedRow()` → `List<Map>`
  - `bookmark(feedId)` / `unbookmark(feedId)` / `isBookmarked(feedId)`
- `bookmarks_screen.dart` 수정
  - `_loadBookmarks()` → `BookmarkService.instance.getBookmarkedFeeds()` 호출
  - 피드 탭만 연동 (뮤지션/음악 탭은 현재 DB 스키마 미지원 → 빈 상태 유지)
  - 삭제 버튼 → `unbookmark()` 호출

> 현재 `bookmarks_screen`의 뮤지션/음악 탭: 빈 리스트로 두되 "준비 중" 메시지 표시

---

### C-4: `like_service.dart` 신규 + `liked_content_screen.dart` 연동

- `lib/core/services/like_service.dart` 신규 생성
  - `getLikedFeeds()` → `_mapFeedRow()` → `List<Map>`
  - `like(feedId)` / `unlike(feedId)` / `isLiked(feedId)`
- `liked_content_screen.dart` 수정
  - `_loadLikedContent()` → `LikeService.instance.getLikedFeeds()` 호출
  - 피드 탭만 연동 (뮤지션/음악 탭 → "준비 중")
  - 좋아요 취소 버튼 → `unlike()` 호출

> `home_tab.dart`의 하트 버튼도 `LikeService`를 호출하도록 교체 (C-4 마지막 단계)

---

### C-5: `search_tab.dart` — Supabase profiles 검색 연동

현재: `_loadExtendedMusicianData()`에서 10명 하드코딩  
목표: `supabase_service.searchProfiles(query)` 호출

변경 범위:
- `search_tab.dart`에서 `SearchService` 대신 `SupabaseService.instance.searchProfiles()` 직접 호출
- 검색어 변경 시 디바운스(300ms) → Supabase ilike 쿼리
- 결과 없으면 빈 상태 UI 표시
- `SearchService`의 캐시/히스토리 로직은 그대로 유지 (로컬 기능이므로)

---

### C-6: `profile_tab.dart` — 팔로워/팔로잉 수 실제 값으로 교체

현재: `'팔로워', '1.2K'` (하드코딩)  
목표: `FollowService.instance.getFollowerCount()` / `getFollowingCount()` 호출

변경 범위:
- `_ProfileTabState`에 `int _followerCount`, `int _followingCount` 필드 추가
- `initState()`에서 비동기 로드 (`_loadStats()`)
- `_buildStatItem` 호출 부분에서 실제 count 값 사용

> `FollowService`에 `getFollowerCount(userId)`, `getFollowingCount(userId)` 메서드 추가 필요  
> `supabase_service.dart`에 `getFollowerCount` / `getFollowingCount` raw 메서드도 추가 (C-2에서 함께 처리)

---

## Phase D — 마무리 & 배포 준비

**왜 D인가?** 핵심 사용자 흐름은 C에서 완성. D는 "있으면 좋은" 기능과 최종 정리.

### D-1: `my_music_screen.dart` — 내 피드(음악) 연동

현재: 5개 하드코딩된 음악  
목표: `FeedService.instance.getMyFeeds()` 호출 (내가 올린 feeds)

- `feed_service.dart`에 `getMyFeeds()` 추가 → `feeds` WHERE `user_id = me`
- `my_music_screen.dart`의 `_loadMyMusic()` 교체
- 삭제 → `FeedService.instance.deleteFeed(id)` 호출

---

### D-2: `recommendation_service.dart` — profiles 기반 단순 추천으로 교체

현재: 3명 하드코딩  
목표: `getCandidates()`를 재활용해 랜덤 5명 추천 (이미 ConnectService에 구현됨)

- `RecommendationService.getRecommendedMusicians()` 내부에서  
  `ConnectService.instance.getCandidates()` 호출 후 최대 5명 반환
- 점수 계산 알고리즘은 건드리지 않음

---

### D-3: 최종 정리 & 배포

| 항목 | 내용 |
|------|------|
| `flutter analyze --no-pub` | No issues found! 최종 확인 |
| `CLAUDE.md` 업데이트 | Phase C, D 완료 상태 반영 |
| git commit | `feat: Phase C/D Supabase bridge complete` |
| git push | `origin feat/supabase-bridge` |
| PR 생성 | master 브랜치로 머지 준비 |

---

## 작업 순서 & 의존성 그래프

```
C-1 (DB 마이그레이션)
  └── C-2 (supabase_service raw 메서드)
        ├── C-3 (BookmarkService + bookmarks_screen)
        ├── C-4 (LikeService + liked_content_screen + home_tab 하트)
        └── C-5 (search_tab 검색 연동)
C-6 (profile_tab 통계) ← FollowService 확장 (독립적)
        │
        ▼
D-1 (my_music_screen) ← FeedService 확장 (독립적)
D-2 (recommendation_service 교체)
        │
        ▼
D-3 (최종 정리 & push)
```

---

## 스코프 밖 (이번 브랜치에서 제외)

| 항목 | 이유 |
|------|------|
| `offline_service.dart` 실제 동기화 | 충돌 해결 알고리즘 = 별도 프로젝트 수준 |
| `profile_settings_screen.dart` 클라우드 동기화 | 설정은 로컬이 적합, 비용 대비 효과 낮음 |
| 북마크/좋아요 뮤지션·음악 탭 | DB 스키마 미지원, 별도 마이그레이션 필요 |
| 푸시 알림 (FCM) | Supabase realtime 구독으로 대체 완료 |
| 라이브 스트리밍 (`live_streaming_screen.dart`) | 별도 인프라 필요 (WebRTC 등) |

---

## 핵심 스키마 메모 (전체)

| 테이블 | 주요 컬럼 |
|--------|-----------|
| `profiles` | `id, username, nickname, bio, instruments, avatar_url` |
| `feeds` | `id, user_id, title, content, media_url, likes_count` |
| `comments` | `id, feed_id, user_id, content` |
| `jam_sessions` | `id, creator_id, title, genre, max_participants` |
| `chat_messages` | `id, room_id, sender_id, content` |
| `follows` | `follower_id, following_id` |
| `connect_likes` | `from_id, to_id` |
| `matches` | `user1_id, user2_id` (user1_id < user2_id UUID 순) |
| `notifications` | `user_id, type, payload, read` |
| `bookmarks` *(C-1)* | `user_id, feed_id` |
| `feed_likes` *(C-1)* | `user_id, feed_id` |
