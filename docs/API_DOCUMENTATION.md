# 🎵 JamJam API 문서

**마지막 업데이트**: 2024년 8월 4일  
**버전**: 1.0.0

## 📋 개요

JamJam은 음악인들을 연결하는 소셜 플랫폼입니다. 이 문서는 JamJam의 백엔드 API에 대한 상세한 설명을 제공합니다.

## 🔐 인증

### 기본 정보
- **인증 방식**: JWT (JSON Web Token)
- **토큰 만료**: 24시간
- **갱신**: 자동 갱신 지원

### 인증 헤더
```http
Authorization: Bearer <jwt_token>
```

## 👤 사용자 API

### 회원가입
```http
POST /auth/signup
```

**요청 본문**:
```json
{
  "email": "user@example.com",
  "password": "password123",
  "userData": {
    "nickname": "user_nickname"
  }
}
```

**응답**:
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "created_at": "2024-08-04T12:00:00Z"
  },
  "session": {
    "access_token": "jwt_token",
    "refresh_token": "refresh_token"
  }
}
```

### 로그인
```http
POST /auth/login
```

**요청 본문**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**응답**:
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com"
  },
  "session": {
    "access_token": "jwt_token",
    "refresh_token": "refresh_token"
  }
}
```

### 프로필 조회
```http
GET /profiles/{user_id}
```

**응답**:
```json
{
  "id": "uuid",
  "username": "user@example.com",
  "nickname": "user_nickname",
  "bio": "음악을 사랑하는 사용자입니다 🎵",
  "avatar_url": "https://example.com/avatar.jpg",
  "instruments": ["guitar", "piano"],
  "location": "Seoul",
  "created_at": "2024-08-04T12:00:00Z",
  "updated_at": "2024-08-04T12:00:00Z"
}
```

### 프로필 수정
```http
PUT /profiles/{user_id}
```

**요청 본문**:
```json
{
  "nickname": "new_nickname",
  "bio": "새로운 자기소개",
  "instruments": ["guitar", "piano", "drums"],
  "location": "Busan"
}
```

## 📱 피드 API

### 피드 조회
```http
GET /feeds?limit=10&offset=0
```

**응답**:
```json
{
  "feeds": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "content": "새로운 곡을 업로드했습니다!",
      "media_urls": ["https://example.com/music.mp3"],
      "likes_count": 5,
      "comments_count": 3,
      "created_at": "2024-08-04T12:00:00Z",
      "user": {
        "id": "uuid",
        "nickname": "user_nickname",
        "avatar_url": "https://example.com/avatar.jpg"
      }
    }
  ],
  "total": 100,
  "has_more": true
}
```

### 피드 생성
```http
POST /feeds
```

**요청 본문**:
```json
{
  "content": "새로운 곡을 업로드했습니다!",
  "media_urls": ["https://example.com/music.mp3"],
  "jam_session_id": "uuid"
}
```

### 좋아요 토글
```http
POST /feeds/{feed_id}/like
```

**응답**:
```json
{
  "liked": true,
  "likes_count": 6
}
```

### 댓글 추가
```http
POST /feeds/{feed_id}/comments
```

**요청 본문**:
```json
{
  "content": "정말 좋은 곡이네요!"
}
```

## 🎵 Jam 세션 API

### Jam 세션 생성
```http
POST /jam_sessions
```

**요청 본문**:
```json
{
  "title": "재즈 Jam 세션",
  "description": "재즈 음악을 함께 연주해요!",
  "instruments": ["piano", "saxophone"],
  "max_participants": 5
}
```

### Jam 세션 조회
```http
GET /jam_sessions?limit=10&offset=0
```

**응답**:
```json
{
  "sessions": [
    {
      "id": "uuid",
      "creator_id": "uuid",
      "title": "재즈 Jam 세션",
      "description": "재즈 음악을 함께 연주해요!",
      "instruments": ["piano", "saxophone"],
      "max_participants": 5,
      "current_participants": 3,
      "status": "open",
      "created_at": "2024-08-04T12:00:00Z",
      "creator": {
        "id": "uuid",
        "nickname": "creator_nickname",
        "avatar_url": "https://example.com/avatar.jpg"
      }
    }
  ]
}
```

### Jam 세션 참여
```http
POST /jam_sessions/{session_id}/join
```

### Jam 세션 탈퇴
```http
POST /jam_sessions/{session_id}/leave
```

## 💬 채팅 API

### 채팅 메시지 조회
```http
GET /jam_sessions/{session_id}/messages?limit=50&offset=0
```

**응답**:
```json
{
  "messages": [
    {
      "id": "uuid",
      "jam_session_id": "uuid",
      "user_id": "uuid",
      "message": "안녕하세요!",
      "message_type": "text",
      "created_at": "2024-08-04T12:00:00Z",
      "user": {
        "id": "uuid",
        "nickname": "user_nickname",
        "avatar_url": "https://example.com/avatar.jpg"
      }
    }
  ]
}
```

### 채팅 메시지 전송
```http
POST /jam_sessions/{session_id}/messages
```

**요청 본문**:
```json
{
  "message": "안녕하세요!",
  "message_type": "text"
}
```

## 🔍 검색 API

### 사용자 검색
```http
GET /search/users?q=keyword&limit=10
```

**응답**:
```json
{
  "users": [
    {
      "id": "uuid",
      "nickname": "user_nickname",
      "bio": "음악을 사랑하는 사용자입니다",
      "instruments": ["guitar", "piano"],
      "avatar_url": "https://example.com/avatar.jpg"
    }
  ]
}
```

### 콘텐츠 검색
```http
GET /search/feeds?q=keyword&limit=10
```

## 📊 에러 코드

### 일반적인 에러 코드
- `400`: 잘못된 요청
- `401`: 인증 실패
- `403`: 권한 없음
- `404`: 리소스를 찾을 수 없음
- `500`: 서버 내부 오류

### 에러 응답 예시
```json
{
  "error": {
    "code": "AUTH_FAILED",
    "message": "이메일 또는 비밀번호가 올바르지 않습니다.",
    "details": {}
  }
}
```

## 🔄 실시간 기능

### WebSocket 연결
```javascript
const channel = supabase
  .channel('jam_session_123')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'chat_messages',
    filter: 'jam_session_id=eq.123'
  }, (payload) => {
    console.log('새 메시지:', payload.new)
  })
  .subscribe()
```

### 실시간 이벤트
- **새 메시지**: `chat_messages` 테이블 INSERT
- **새 피드**: `feeds` 테이블 INSERT
- **좋아요 업데이트**: `feeds` 테이블 UPDATE
- **Jam 세션 상태 변경**: `jam_sessions` 테이블 UPDATE

## 📈 성능 최적화

### 캐싱 전략
- **사용자 프로필**: 1시간 캐시
- **피드 목록**: 5분 캐시
- **Jam 세션 목록**: 10분 캐시

### 페이지네이션
- **기본 제한**: 20개
- **최대 제한**: 100개
- **오프셋 기반**: 무한 스크롤 지원

### 미디어 업로드
- **최대 파일 크기**: 50MB
- **지원 형식**: MP3, WAV, MP4, JPG, PNG
- **CDN**: 자동 최적화 및 배포

## 🔒 보안

### 데이터 보호
- **Row Level Security (RLS)**: 모든 테이블에 적용
- **JWT 토큰**: 24시간 만료
- **HTTPS**: 모든 통신 암호화

### 권한 관리
- **사용자**: 자신의 데이터만 수정 가능
- **공개 데이터**: 프로필, 피드는 공개 읽기
- **개인 데이터**: 메시지, 설정은 비공개

---

**문서 버전**: 1.0.0  
**마지막 업데이트**: 2024년 8월 4일 