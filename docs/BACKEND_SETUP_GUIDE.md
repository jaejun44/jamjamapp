# 🔧 JamJam 백엔드 설정 가이드

**마지막 업데이트**: 2024년 8월 4일  
**버전**: 1.0.0

## 📋 개요

이 가이드는 JamJam 프로젝트의 백엔드 설정을 위한 단계별 지침을 제공합니다.

## 🚀 1단계: Supabase 프로젝트 설정

### 1.1 Supabase 대시보드 접속
1. [Supabase 대시보드](https://supabase.com/dashboard)에 접속
2. 로그인 또는 회원가입
3. 새 프로젝트 생성

### 1.2 프로젝트 생성
- **프로젝트 이름**: jamjam
- **데이터베이스 비밀번호**: 안전한 비밀번호 설정
- **지역**: 가장 가까운 지역 선택 (예: Asia Pacific - Singapore)

### 1.3 프로젝트 설정 확인
- **URL**: `https://aadlqmyynidfsygnxnnk.supabase.co`
- **Anon Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFhZGxxbXl5bmlkZnN5Z254bm5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyNDIwMjUsImV4cCI6MjA2OTgxODAyNX0.6ymus7BN145eQsKHSOBwajuCq17fjIEd7Hf0fpTZ-8Y`

## 🗄️ 2단계: 데이터베이스 스키마 설정

### 2.1 SQL 편집기 접속
1. Supabase 대시보드에서 프로젝트 선택
2. 왼쪽 메뉴에서 "SQL Editor" 클릭
3. "New query" 클릭

### 2.2 마이그레이션 실행
다음 SQL 쿼리들을 순서대로 실행:

#### 2.2.1 프로필 테이블 생성
```sql
-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE,
  nickname TEXT,
  bio TEXT,
  avatar_url TEXT,
  instruments TEXT[],
  location TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Public profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS profiles_username_idx ON profiles(username);
CREATE INDEX IF NOT EXISTS profiles_nickname_idx ON profiles(nickname);
CREATE INDEX IF NOT EXISTS profiles_location_idx ON profiles(location);
CREATE INDEX IF NOT EXISTS profiles_created_at_idx ON profiles(created_at DESC);

-- Create function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, nickname)
  VALUES (NEW.id, NEW.email, split_part(NEW.email, '@', 1));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user signup
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

#### 2.2.2 피드 테이블 생성
```sql
-- Create feeds table
CREATE TABLE IF NOT EXISTS feeds (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  media_urls TEXT[],
  jam_session_id UUID,
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE feeds ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Feeds are viewable by everyone" ON feeds
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own feeds" ON feeds
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own feeds" ON feeds
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own feeds" ON feeds
  FOR DELETE USING (auth.uid() = user_id);

-- Create indexes
CREATE INDEX IF NOT EXISTS feeds_user_id_idx ON feeds(user_id);
CREATE INDEX IF NOT EXISTS feeds_created_at_idx ON feeds(created_at DESC);
CREATE INDEX IF NOT EXISTS feeds_jam_session_id_idx ON feeds(jam_session_id);
```

#### 2.2.3 Jam 세션 테이블 생성
```sql
-- Create jam_sessions table
CREATE TABLE IF NOT EXISTS jam_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  creator_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  instruments TEXT[],
  max_participants INTEGER DEFAULT 10,
  current_participants INTEGER DEFAULT 1,
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'full', 'closed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE jam_sessions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Jam sessions are viewable by everyone" ON jam_sessions
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own jam sessions" ON jam_sessions
  FOR INSERT WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Users can update their own jam sessions" ON jam_sessions
  FOR UPDATE USING (auth.uid() = creator_id);

CREATE POLICY "Users can delete their own jam sessions" ON jam_sessions
  FOR DELETE USING (auth.uid() = creator_id);

-- Create indexes
CREATE INDEX IF NOT EXISTS jam_sessions_creator_id_idx ON jam_sessions(creator_id);
CREATE INDEX IF NOT EXISTS jam_sessions_status_idx ON jam_sessions(status);
CREATE INDEX IF NOT EXISTS jam_sessions_created_at_idx ON jam_sessions(created_at DESC);
```

#### 2.2.4 채팅 메시지 테이블 생성
```sql
-- Create chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  jam_session_id UUID REFERENCES jam_sessions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'audio')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Chat messages are viewable by session participants" ON chat_messages
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own messages" ON chat_messages
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own messages" ON chat_messages
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own messages" ON chat_messages
  FOR DELETE USING (auth.uid() = user_id);

-- Create indexes
CREATE INDEX IF NOT EXISTS chat_messages_jam_session_id_idx ON chat_messages(jam_session_id);
CREATE INDEX IF NOT EXISTS chat_messages_user_id_idx ON chat_messages(user_id);
CREATE INDEX IF NOT EXISTS chat_messages_created_at_idx ON chat_messages(created_at DESC);
```

## 🔐 3단계: 인증 설정

### 3.1 Auth 설정
1. Supabase 대시보드에서 "Authentication" 메뉴 클릭
2. "Settings" 탭에서 다음 설정 확인:
   - **Site URL**: `http://localhost:8182` (개발용)
   - **Redirect URLs**: `http://localhost:8182/**`
   - **Enable email confirmations**: 비활성화 (개발용)

### 3.2 RLS 정책 확인
모든 테이블에 Row Level Security가 활성화되어 있는지 확인:
- profiles
- feeds
- jam_sessions
- chat_messages

## 📁 4단계: Storage 설정

### 4.1 Storage 버킷 생성
1. Supabase 대시보드에서 "Storage" 메뉴 클릭
2. "New bucket" 클릭
3. 다음 버킷들 생성:
   - **avatars**: 프로필 이미지용
   - **feeds**: 피드 미디어용
   - **jam_sessions**: Jam 세션 미디어용

### 4.2 Storage 정책 설정
각 버킷에 대해 다음 정책 설정:

```sql
-- avatars 버킷 정책
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update their own avatar" ON storage.objects
  FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own avatar" ON storage.objects
  FOR DELETE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
```

## 🔄 5단계: 실시간 설정

### 5.1 Realtime 활성화
1. Supabase 대시보드에서 "Database" 메뉴 클릭
2. "Replication" 탭에서 다음 테이블들 활성화:
   - profiles
   - feeds
   - jam_sessions
   - chat_messages

## 🧪 6단계: 테스트

### 6.1 연결 테스트
앱에서 "백엔드 테스트" 기능을 사용하여 연결 상태 확인

### 6.2 수동 테스트
Supabase 대시보드에서 직접 데이터 삽입 테스트:

```sql
-- 테스트 데이터 삽입
INSERT INTO profiles (id, username, nickname, bio, instruments)
VALUES (
  'test-user-id',
  'test@example.com',
  'TestUser',
  '테스트 사용자입니다',
  ARRAY['guitar', 'piano']
);
```

## 🚨 문제 해결

### 일반적인 문제들

#### 1. 연결 실패
- **원인**: 잘못된 URL 또는 Anon Key
- **해결**: 프로젝트 설정에서 올바른 값 확인

#### 2. RLS 오류
- **원인**: Row Level Security 정책이 잘못 설정됨
- **해결**: 정책을 다시 생성하거나 비활성화 (개발용)

#### 3. 마이그레이션 실패
- **원인**: SQL 구문 오류 또는 권한 문제
- **해결**: 쿼리를 하나씩 실행하여 오류 확인

#### 4. Storage 접근 오류
- **원인**: Storage 버킷이 생성되지 않음
- **해결**: 버킷을 생성하고 정책 설정

## 📞 지원

문제가 발생하면 다음을 확인하세요:
1. Supabase 대시보드의 로그 확인
2. 브라우저 개발자 도구의 네트워크 탭 확인
3. Flutter 앱의 콘솔 로그 확인

---

**문서 버전**: 1.0.0  
**마지막 업데이트**: 2024년 8월 4일 