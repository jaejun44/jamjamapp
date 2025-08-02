# JamJam 앱 개발 문서

## 📋 문서 목록

### 1. [개발 목적 및 목표](./01_DEVELOPMENT_PURPOSE_AND_GOALS.md)
- 프로젝트 개요 및 핵심 목표
- 개발 철학 및 기술 스택
- 앱 구조 및 개발 단계
- 향후 계획

### 2. [1차 프론트엔드 개발 구현 현황](./02_FRONTEND_IMPLEMENTATION_STATUS.md)
- 구현 완료된 13개 주요 기능
- 코드 구조 및 기술적 성과
- 구현 통계 및 성과 지표

### 3. [백엔드 연결 시 수정/삭제/보안 요구사항](./03_BACKEND_INTEGRATION_REQUIREMENTS.md)
- 삭제해야 할 모의 데이터
- 수정해야 할 API 연동 코드
- 보안 강화가 필요한 부분
- 마이그레이션 계획

## 🚀 현재 개발 상태

### ✅ 완료된 작업 (Phase 1)
- **앱 테마 및 디자인 시스템** (Black + Pink)
- **메인 네비게이션 구조** (5개 탭)
- **홈 피드 UI** (Vampr Watch 탭 스타일)
- **검색 및 필터링 기능 UI**
- **Jam 세션 생성 UI**
- **채팅 시스템 UI**
- **프로필 관리 시스템 UI**
- **인증 시스템 UI** (로그인/회원가입/비밀번호 찾기)
- **이미지 업로드 및 프로필 편집 기능**
- **로컬 데이터 저장** (SharedPreferences)

### 🔄 진행 예정 (Phase 2)
- **Supabase 인증 시스템 연동**
- **실시간 데이터베이스 연동**
- **파일 스토리지 연동**
- **실시간 채팅 기능 구현**
- **푸시 알림 시스템**

### 📈 향후 계획 (Phase 3-4)
- **음악 파일 업로드/재생**
- **실시간 음악 협업**
- **위치 기반 음악인 매칭**
- **음악 이벤트 관리**

## 🛠️ 기술 스택

### 현재 사용 중
- **Flutter**: 크로스 플랫폼 개발
- **Dart**: 프로그래밍 언어
- **Material Design**: UI 컴포넌트
- **SharedPreferences**: 로컬 데이터 저장
- **image_picker**: 이미지 선택

### 추가 예정
- **Supabase**: BaaS (Backend as a Service)
- **flutter_riverpod**: 상태 관리
- **flutter_secure_storage**: 보안 저장소
- **supabase_flutter**: Supabase 클라이언트

## 📱 앱 구조

```
lib/
├── core/
│   ├── theme/
│   │   └── app_theme.dart          # 앱 테마 (Black + Pink)
│   └── config/                     # 설정 파일 (예정)
├── features/
│   ├── home/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── main_screen.dart # 메인 네비게이션
│   │       └── widgets/
│   │           ├── home_tab.dart    # 홈 피드
│   │           ├── search_tab.dart  # 검색
│   │           ├── jam_creation_tab.dart # Jam 생성
│   │           ├── chat_tab.dart    # 채팅 목록
│   │           └── profile_tab.dart # 프로필
│   ├── auth/
│   │   └── presentation/
│   │       └── widgets/
│   │           ├── login_modal.dart     # 로그인
│   │           ├── signup_modal.dart    # 회원가입
│   │           └── forgot_password_modal.dart # 비밀번호 찾기
│   └── chat/
│       └── presentation/
│           └── screens/
│               └── chat_room_screen.dart # 채팅방
└── main.dart                       # 앱 진입점
```

## 🎯 핵심 기능

### 1. 홈 피드
- Vampr Watch 탭 스타일의 피드
- 좋아요/저장 버튼 상태 관리
- FloatingActionButton (+ 버튼)
- 피드 추가 모달 (영상, 음원, 사진, 텍스트)

### 2. 검색 및 필터링
- 실시간 검색 결과 표시
- 장르 및 악기별 필터링
- 음악인 카드 레이아웃
- 팔로우 기능

### 3. Jam 세션
- Jam 세션 생성 폼
- 폼 검증 시스템
- 세션 상태 표시 (모집 중, 진행 중, 완료)
- 참여 신청/상세 보기

### 4. 채팅 시스템
- 채팅 목록 및 채팅방
- 메시지 버블 디자인
- 타이핑 인디케이터
- 온라인 상태 표시

### 5. 프로필 관리
- 로그인/비로그인 상태 관리
- 프로필 정보 편집
- 이미지 업로드
- 로컬 데이터 영구 저장

## 🔒 보안 고려사항

### 현재 상태
- SharedPreferences에 민감한 데이터 저장 (보안 위험)
- 하드코딩된 API 키 (환경 변수 필요)
- 기본적인 입력 검증

### 개선 필요
- `flutter_secure_storage` 사용
- 환경 변수로 API 키 관리
- 강화된 입력 검증 (XSS 방지)
- 파일 업로드 보안 검증

## 📊 성과 지표

### 구현 완료
- **총 13개 주요 기능** 구현 완료
- **5개 주요 화면** 모두 구현
- **8개 모달/위젯** 구현
- **로컬 데이터 저장** 시스템 구축

### 기술적 성과
- **웹 환경 최적화**: 이미지 처리, 상태 관리
- **모듈화된 구조**: 유지보수성 향상
- **사용자 경험**: 직관적인 인터페이스
- **확장성**: 백엔드 연동 준비 완료

## 🚨 주의사항

### 백엔드 연동 시
1. **모의 데이터 삭제**: 모든 하드코딩된 데이터 제거
2. **API 연동**: Supabase 클라이언트 추가
3. **보안 강화**: 토큰 관리 및 입력 검증
4. **상태 관리**: Riverpod 패턴으로 변경

### 데이터 마이그레이션
- SharedPreferences 데이터를 Supabase로 마이그레이션
- 사용자 동의 필요
- 데이터 손실 방지

## 📞 연락처

**개발자**: JamJam 팀
**프로젝트**: 음악인들을 위한 소셜 네트워킹 플랫폼
**개발 방식**: Vibe Coding (AI 협업)

---

**마지막 업데이트**: 2025년 8월
**개발 상태**: Phase 1 완료 (프론트엔드 개발 완료)
**다음 단계**: Phase 2 (백엔드 연동) 