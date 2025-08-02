# 🎵 JamJam - 음악인을 위한 소셜 플랫폼

JamJam은 음악인들이 서로 연결하고 협업할 수 있는 소셜 플랫폼입니다. 음악 공유, 실시간 채팅, Jam 세션 생성 등의 기능을 제공합니다.

## 🚀 주요 기능

### 📱 홈 탭 (완성)
- ✅ **무한 스크롤** - 성능 최적화된 피드 로딩
- ✅ **실시간 업데이트** - 새 피드 자동 갱신
- ✅ **미디어 재생** - 비디오/오디오 플레이어
- ✅ **피드 필터링** - 장르별, 타입별 필터
- ✅ **피드 검색** - 내용 검색 기능
- ✅ **미디어 풀스크린** - 확대 보기 기능
- ✅ **피드 공유** - 외부 공유
- ✅ **팔로우 시스템** - 작성자 팔로우
- ✅ **피드 편집/삭제** - 작성자 편집
- ✅ **라이브 스트리밍** - 라이브 방송
- ✅ **개인화 추천** - 맞춤 피드
- ✅ **오프라인 지원** - 네트워크 없이 동작
- ✅ **트렌딩 피드** - 인기 피드 표시
- ✅ **신고 기능** - 부적절한 콘텐츠 신고

### 🔍 검색 탭 (완성)
- ✅ **실시간 검색** - 타이핑과 동시에 결과 표시
- ✅ **고급 검색 알고리즘** - Levenshtein, Jaro-Winkler 유사도
- ✅ **태그 기반 검색** - 가중치 기반 정확도
- ✅ **다중 필터링** - 장르, 타입, 날짜별 필터
- ✅ **정렬 옵션** - 관련도, 최신순, 인기순
- ✅ **검색 제안** - 자동완성 및 추천
- ✅ **검색 히스토리** - 최근 검색어 관리
- ✅ **즐겨찾기** - 자주 사용하는 검색어 저장
- ✅ **검색 통계** - 검색 결과 분석
- ✅ **캐싱 시스템** - 검색 결과 캐싱
- ✅ **에러 처리** - 네트워크 오류, 데이터 검증
- ✅ **무한 스크롤** - 대용량 결과 처리

### 🎼 Jam Creation 탭 (기본 UI)
- ⚙️ Jam 세션 생성 폼
- ⚙️ 최근 Jam 세션 목록
- ⚙️ 참가자 관리

### 💬 Chat 탭 (기본 UI)
- ⚙️ 채팅 목록
- ⚙️ 실시간 메시지
- ⚙️ 미디어 공유

### 👤 Profile 탭 (기본 기능)
- ⚙️ 프로필 관리
- ⚙️ 설정 옵션
- ⚙️ 로그인/로그아웃

## 🛠 기술 스택

- **Framework**: Flutter 3.32.6
- **Language**: Dart
- **State Management**: Provider
- **UI**: Material Design 3
- **Media**: Video Player, Audio Players
- **Storage**: Shared Preferences
- **Version Management**: FVM

## 📱 지원 플랫폼

- ✅ Web (Chrome)
- ✅ Android
- ✅ iOS
- ✅ macOS
- ✅ Windows
- ✅ Linux

## 🚀 실행 방법

### 필수 요구사항
- Flutter 3.32.6
- Dart 3.8.1
- FVM (Flutter Version Management)

### 설치 및 실행

```bash
# FVM 설치 (이미 설치되어 있다면 생략)
dart pub global activate fvm

# Flutter 버전 설정
fvm install 3.32.6
fvm use 3.32.6

# 의존성 설치
fvm flutter pub get

# 웹에서 실행
fvm flutter run -d chrome --web-port=8150

# 모바일에서 실행
fvm flutter run -d android
fvm flutter run -d ios
```

## 📁 프로젝트 구조

```
lib/
├── core/
│   ├── services/
│   │   ├── search_service.dart
│   │   ├── recommendation_service.dart
│   │   └── offline_service.dart
│   ├── utils/
│   │   └── search_utils.dart
│   └── theme/
│       └── app_theme.dart
├── features/
│   ├── home/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── main_screen.dart
│   │       └── widgets/
│   │           ├── home_tab.dart
│   │           ├── search_tab.dart
│   │           ├── jam_creation_tab.dart
│   │           ├── chat_tab.dart
│   │           └── profile_tab.dart
│   ├── auth/
│   └── chat/
└── main.dart
```

## 🔧 최근 수정사항

### 🔧 디버깅 완료 (2024-08-03)
- ✅ TabController 오류 수정 - DefaultTabController 추가
- ✅ null 안전성 오류 수정 - XFile?.name null 체크
- ✅ 타입 오류 수정 - compareTo 메서드 타입 캐스팅
- ✅ 매개변수 오류 수정 - onReportFeed 제거

### 🎉 기능 구현 완료 (2024-08-03)
- ✅ 홈 탭 15개 주요 기능 완성
- ✅ 검색 탭 12개 고급 기능 완성
- ✅ 실시간 업데이트, 풀스크린, 공유 기능
- ✅ 라이브 스트리밍, 개인화 추천, 오프라인 지원

## 🎯 개발 로드맵

### ✅ 완료된 기능
- [x] 홈 탭 - 완전한 기능 구현
- [x] 검색 탭 - 고급 검색 시스템
- [x] 기본 UI 구조
- [x] 디버깅 및 오류 수정

### 🚧 진행 중인 기능
- [ ] Jam Creation 탭 - 실제 Jam 세션 기능
- [ ] Chat 탭 - 실시간 채팅 기능
- [ ] Profile 탭 - 고급 프로필 관리

### 📋 예정된 기능
- [ ] 백엔드 연동
- [ ] 실시간 데이터베이스
- [ ] 푸시 알림
- [ ] 소셜 로그인
- [ ] 파일 업로드 서버

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 연락처

프로젝트 링크: [https://github.com/jaejun44/jamjamapp](https://github.com/jaejun44/jamjamapp)

---

**JamJam** - 음악인을 위한 소셜 플랫폼 🎵
