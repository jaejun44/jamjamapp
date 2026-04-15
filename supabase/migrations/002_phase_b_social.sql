-- ============================================================
-- JamJam Phase B: 소셜 기능 스키마
-- follows / connect_likes / matches / notifications
-- Supabase Dashboard > SQL Editor에서 실행
-- ============================================================

-- ────────────────────────────────────────
-- 1. follows 테이블
-- ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS follows (
  follower_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (follower_id, following_id)
);

-- 팔로잉 목록 조회 최적화 인덱스
CREATE INDEX IF NOT EXISTS follows_follower_idx  ON follows (follower_id);
CREATE INDEX IF NOT EXISTS follows_following_idx ON follows (following_id);

-- ────────────────────────────────────────
-- 2. connect_likes 테이블
-- ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS connect_likes (
  from_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  to_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (from_id, to_id)
);

CREATE INDEX IF NOT EXISTS connect_likes_from_idx ON connect_likes (from_id);
CREATE INDEX IF NOT EXISTS connect_likes_to_idx   ON connect_likes (to_id);

-- ────────────────────────────────────────
-- 3. matches 테이블
-- ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS matches (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user1_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user2_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  chat_room_id UUID REFERENCES chat_rooms(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- 중복 매치 방지: (user1, user2) 순서 무관하게 유니크
  CONSTRAINT matches_unique CHECK (user1_id < user2_id),
  UNIQUE (user1_id, user2_id)
);

CREATE INDEX IF NOT EXISTS matches_user1_idx ON matches (user1_id);
CREATE INDEX IF NOT EXISTS matches_user2_idx ON matches (user2_id);

-- ────────────────────────────────────────
-- 4. notifications 테이블
-- ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type       TEXT NOT NULL CHECK (type IN ('follow', 'comment', 'like', 'match')),
  payload    JSONB NOT NULL DEFAULT '{}',
  read       BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS notifications_user_id_idx    ON notifications (user_id);
CREATE INDEX IF NOT EXISTS notifications_user_read_idx  ON notifications (user_id, read);

-- ────────────────────────────────────────
-- 5. RLS 활성화
-- ────────────────────────────────────────
ALTER TABLE follows        ENABLE ROW LEVEL SECURITY;
ALTER TABLE connect_likes  ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches        ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications  ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────
-- 6. RLS 정책 — follows
-- ────────────────────────────────────────
DROP POLICY IF EXISTS "follows_select_all"      ON follows;
DROP POLICY IF EXISTS "follows_insert_own"      ON follows;
DROP POLICY IF EXISTS "follows_delete_own"      ON follows;

CREATE POLICY "follows_select_all"
  ON follows FOR SELECT USING (true);

CREATE POLICY "follows_insert_own"
  ON follows FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "follows_delete_own"
  ON follows FOR DELETE USING (auth.uid() = follower_id);

-- ────────────────────────────────────────
-- 7. RLS 정책 — connect_likes
-- ────────────────────────────────────────
DROP POLICY IF EXISTS "connect_likes_select_own"  ON connect_likes;
DROP POLICY IF EXISTS "connect_likes_insert_own"  ON connect_likes;

CREATE POLICY "connect_likes_select_own"
  ON connect_likes FOR SELECT
  USING (auth.uid() = from_id OR auth.uid() = to_id);

CREATE POLICY "connect_likes_insert_own"
  ON connect_likes FOR INSERT WITH CHECK (auth.uid() = from_id);

-- ────────────────────────────────────────
-- 8. RLS 정책 — matches
-- ────────────────────────────────────────
DROP POLICY IF EXISTS "matches_select_own"   ON matches;
DROP POLICY IF EXISTS "matches_insert_auth"  ON matches;

CREATE POLICY "matches_select_own"
  ON matches FOR SELECT
  USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "matches_insert_auth"
  ON matches FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ────────────────────────────────────────
-- 9. RLS 정책 — notifications
-- ────────────────────────────────────────
DROP POLICY IF EXISTS "notifications_select_own"  ON notifications;
DROP POLICY IF EXISTS "notifications_update_own"  ON notifications;
DROP POLICY IF EXISTS "notifications_insert_auth" ON notifications;

CREATE POLICY "notifications_select_own"
  ON notifications FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "notifications_update_own"
  ON notifications FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "notifications_insert_auth"
  ON notifications FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ────────────────────────────────────────
-- 10. DB Function — 팔로우 알림 자동 생성
-- ────────────────────────────────────────
CREATE OR REPLACE FUNCTION notify_on_follow()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO notifications (user_id, type, payload)
  VALUES (
    NEW.following_id,
    'follow',
    jsonb_build_object('follower_id', NEW.follower_id)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_follow ON follows;
CREATE TRIGGER trg_notify_follow
  AFTER INSERT ON follows
  FOR EACH ROW EXECUTE FUNCTION notify_on_follow();

-- ────────────────────────────────────────
-- 11. DB Function — 매칭 알림 자동 생성
-- ────────────────────────────────────────
CREATE OR REPLACE FUNCTION notify_on_match()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- user1에게 알림
  INSERT INTO notifications (user_id, type, payload)
  VALUES (
    NEW.user1_id,
    'match',
    jsonb_build_object('matched_user_id', NEW.user2_id, 'match_id', NEW.id)
  );
  -- user2에게 알림
  INSERT INTO notifications (user_id, type, payload)
  VALUES (
    NEW.user2_id,
    'match',
    jsonb_build_object('matched_user_id', NEW.user1_id, 'match_id', NEW.id)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_match ON matches;
CREATE TRIGGER trg_notify_match
  AFTER INSERT ON matches
  FOR EACH ROW EXECUTE FUNCTION notify_on_match();

-- ────────────────────────────────────────
-- 12. Realtime 구독 활성화
-- ────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE follows;
ALTER PUBLICATION supabase_realtime ADD TABLE matches;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
