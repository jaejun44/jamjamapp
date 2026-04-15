-- ============================================================
-- JamJam Phase A-1: DB 스키마 정비
-- Supabase Dashboard > SQL Editor에서 실행
-- ============================================================

-- ────────────────────────────────────────
-- 1. 신규 테이블 생성 (FK 참조 순서: 먼저 생성)
-- ────────────────────────────────────────

-- chat_rooms (chat_messages, chat_members가 참조)
CREATE TABLE IF NOT EXISTS chat_rooms (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT,
  type       TEXT NOT NULL DEFAULT 'dm' CHECK (type IN ('dm', 'group')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- chat_members
CREATE TABLE IF NOT EXISTS chat_members (
  room_id   UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  user_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (room_id, user_id)
);

-- comments
CREATE TABLE IF NOT EXISTS comments (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feed_id    UUID NOT NULL REFERENCES feeds(id) ON DELETE CASCADE,
  author_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content    TEXT NOT NULL,
  likes      INTEGER NOT NULL DEFAULT 0,
  parent_id  UUID REFERENCES comments(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- jam_participants
CREATE TABLE IF NOT EXISTS jam_participants (
  session_id UUID NOT NULL REFERENCES jam_sessions(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role       TEXT NOT NULL DEFAULT 'participant' CHECK (role IN ('host', 'participant')),
  joined_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (session_id, user_id)
);

-- ────────────────────────────────────────
-- 2. 기존 테이블 컬럼 추가
-- ────────────────────────────────────────

-- feeds: 누락 컬럼 추가
ALTER TABLE feeds
  ADD COLUMN IF NOT EXISTS title      TEXT,
  ADD COLUMN IF NOT EXISTS genre      TEXT,
  ADD COLUMN IF NOT EXISTS media_url  TEXT,
  ADD COLUMN IF NOT EXISTS media_type TEXT DEFAULT 'none',
  ADD COLUMN IF NOT EXISTS likes      INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS shares     INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS comments   INTEGER NOT NULL DEFAULT 0;

-- jam_sessions: 누락 컬럼 추가
ALTER TABLE jam_sessions
  ADD COLUMN IF NOT EXISTS genre TEXT;

-- chat_messages: 누락 컬럼 추가 (chat_rooms 생성 후 실행 가능)
ALTER TABLE chat_messages
  ADD COLUMN IF NOT EXISTS room_id   UUID REFERENCES chat_rooms(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS media_url TEXT;

-- ────────────────────────────────────────
-- 3. RLS (Row Level Security) 활성화
-- ────────────────────────────────────────

ALTER TABLE profiles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE feeds            ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments         ENABLE ROW LEVEL SECURITY;
ALTER TABLE jam_sessions     ENABLE ROW LEVEL SECURITY;
ALTER TABLE jam_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rooms       ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_members     ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages    ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────
-- 4. RLS 정책 (기존 정책 제거 후 재생성)
-- ────────────────────────────────────────

-- profiles
DROP POLICY IF EXISTS "profiles_select_all"  ON profiles;
DROP POLICY IF EXISTS "profiles_insert_own"  ON profiles;
DROP POLICY IF EXISTS "profiles_update_own"  ON profiles;

CREATE POLICY "profiles_select_all"
  ON profiles FOR SELECT USING (true);
CREATE POLICY "profiles_insert_own"
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- feeds
DROP POLICY IF EXISTS "feeds_select_all"   ON feeds;
DROP POLICY IF EXISTS "feeds_insert_auth"  ON feeds;
DROP POLICY IF EXISTS "feeds_update_own"   ON feeds;
DROP POLICY IF EXISTS "feeds_delete_own"   ON feeds;

CREATE POLICY "feeds_select_all"
  ON feeds FOR SELECT USING (true);
CREATE POLICY "feeds_insert_auth"
  ON feeds FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "feeds_update_own"
  ON feeds FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "feeds_delete_own"
  ON feeds FOR DELETE USING (auth.uid() = user_id);

-- comments
DROP POLICY IF EXISTS "comments_select_all"   ON comments;
DROP POLICY IF EXISTS "comments_insert_auth"  ON comments;
DROP POLICY IF EXISTS "comments_delete_own"   ON comments;

CREATE POLICY "comments_select_all"
  ON comments FOR SELECT USING (true);
CREATE POLICY "comments_insert_auth"
  ON comments FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "comments_delete_own"
  ON comments FOR DELETE USING (auth.uid() = author_id);

-- jam_sessions
DROP POLICY IF EXISTS "jam_sessions_select_all"   ON jam_sessions;
DROP POLICY IF EXISTS "jam_sessions_insert_auth"  ON jam_sessions;
DROP POLICY IF EXISTS "jam_sessions_update_own"   ON jam_sessions;

CREATE POLICY "jam_sessions_select_all"
  ON jam_sessions FOR SELECT USING (true);
CREATE POLICY "jam_sessions_insert_auth"
  ON jam_sessions FOR INSERT WITH CHECK (auth.uid() = creator_id);
CREATE POLICY "jam_sessions_update_own"
  ON jam_sessions FOR UPDATE USING (auth.uid() = creator_id);

-- jam_participants
DROP POLICY IF EXISTS "jam_participants_select_all"   ON jam_participants;
DROP POLICY IF EXISTS "jam_participants_insert_own"   ON jam_participants;
DROP POLICY IF EXISTS "jam_participants_delete_own"   ON jam_participants;

CREATE POLICY "jam_participants_select_all"
  ON jam_participants FOR SELECT USING (true);
CREATE POLICY "jam_participants_insert_own"
  ON jam_participants FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "jam_participants_delete_own"
  ON jam_participants FOR DELETE USING (auth.uid() = user_id);

-- chat_rooms
DROP POLICY IF EXISTS "chat_rooms_select_member"  ON chat_rooms;
DROP POLICY IF EXISTS "chat_rooms_insert_auth"    ON chat_rooms;

CREATE POLICY "chat_rooms_select_member"
  ON chat_rooms FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_members
      WHERE room_id = chat_rooms.id AND user_id = auth.uid()
    )
  );
CREATE POLICY "chat_rooms_insert_auth"
  ON chat_rooms FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- chat_members
DROP POLICY IF EXISTS "chat_members_select_member"  ON chat_members;
DROP POLICY IF EXISTS "chat_members_insert_auth"    ON chat_members;

CREATE POLICY "chat_members_select_member"
  ON chat_members FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_members cm
      WHERE cm.room_id = chat_members.room_id AND cm.user_id = auth.uid()
    )
  );
CREATE POLICY "chat_members_insert_auth"
  ON chat_members FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- chat_messages
DROP POLICY IF EXISTS "chat_messages_select_member"  ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_insert_auth"    ON chat_messages;

CREATE POLICY "chat_messages_select_member"
  ON chat_messages FOR SELECT USING (
    room_id IS NULL OR EXISTS (
      SELECT 1 FROM chat_members
      WHERE room_id = chat_messages.room_id AND user_id = auth.uid()
    )
  );
CREATE POLICY "chat_messages_insert_auth"
  ON chat_messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- ────────────────────────────────────────
-- 5. Realtime 구독 활성화
-- ────────────────────────────────────────

ALTER PUBLICATION supabase_realtime ADD TABLE comments;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE jam_participants;
