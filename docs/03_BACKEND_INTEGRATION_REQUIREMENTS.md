# 백엔드 연결 시 수정/삭제/보안 요구사항

## 🗑️ 삭제해야 할 코드 (모의 데이터)

### 1. 모의 데이터 배열들
**파일**: `lib/features/home/presentation/widgets/home_tab.dart`
```dart
// 삭제 대상: 모의 피드 데이터
List<Map<String, dynamic>> _feedData = [
  {
    'author': 'JamMaster',
    'title': '재즈 피아노 연주',
    'content': '오늘 연습한 재즈 피아노 곡입니다 🎹',
    'genre': '재즈',
    'likes': 24,
    'comments': 8,
    'shares': 3,
    'timestamp': '2시간 전',
    'mediaType': 'video'
  }
];
```

**파일**: `lib/features/home/presentation/widgets/search_tab.dart`
```dart
// 삭제 대상: 모의 음악인 데이터
List<Map<String, dynamic>> _allMusicians = [
  {
    'name': '재즈마스터',
    'nickname': 'jazz_master',
    'genre': '재즈',
    'instrument': '피아노',
    'followers': 1200,
    'isOnline': true,
  }
];
```

**파일**: `lib/features/home/presentation/widgets/jam_creation_tab.dart`
```dart
// 삭제 대상: 모의 Jam 세션 데이터
List<Map<String, dynamic>> _recentJamSessions = [
  {
    'title': '재즈 피아노 세션',
    'genre': '재즈',
    'instruments': '피아노, 베이스, 드럼',
    'status': '모집 중',
    'createdBy': '재즈마스터',
    'participants': 3,
    'maxParticipants': 5,
  }
];
```

**파일**: `lib/features/home/presentation/widgets/chat_tab.dart`
```dart
// 삭제 대상: 모의 채팅 데이터
List<Map<String, dynamic>> _chatList = [
  {
    'userName': '재즈마스터',
    'userAvatar': 'assets/images/avatar1.jpg',
    'lastMessage': '안녕하세요!',
    'timestamp': '2시간 전',
    'unreadCount': 3,
    'isOnline': true,
    'lastMessageType': 'text',
  }
];
```

### 2. 시뮬레이션 함수들
**파일**: `lib/features/home/presentation/widgets/profile_edit_modal.dart`
```dart
// 삭제 대상: 시뮬레이션된 저장 함수
void _saveProfile() async {
  // 시뮬레이션 코드 삭제
  await Future.delayed(const Duration(seconds: 2));
  
  // 실제 Supabase 저장 로직으로 교체 필요
}
```

**파일**: `lib/features/auth/presentation/widgets/signup_modal.dart`
```dart
// 삭제 대상: 시뮬레이션된 닉네임 중복 검사
Future<void> _checkNicknameAvailability() async {
  // 시뮬레이션 코드 삭제
  await Future.delayed(const Duration(seconds: 1));
  
  // 실제 Supabase 쿼리로 교체 필요
}
```

## 🔧 수정해야 할 코드 (API 연동)

### 1. 상태 관리 시스템
**현재**: StatefulWidget + SharedPreferences
**수정 필요**: Riverpod 또는 Provider 패턴으로 변경

**파일**: `lib/features/home/presentation/widgets/profile_tab.dart`
```dart
// 현재 코드 (수정 필요)
class _ProfileTabState extends State<ProfileTab> {
  bool _isLoggedIn = false;
  String _userName = 'JamMaster';
  
  // 수정 후: Provider 사용
  // final authProvider = ref.read(authProvider.notifier);
  // final userProfile = ref.watch(userProfileProvider);
}
```

### 2. 이미지 업로드 시스템
**파일**: `lib/features/home/presentation/widgets/profile_edit_modal.dart`
```dart
// 현재: 로컬 이미지 처리
void _uploadImage() async {
  final XFile? image = await _picker.pickImage(...);
  final Uint8List imageBytes = await image.readAsBytes();
  
  // 수정 필요: Supabase Storage 업로드
  // final String imageUrl = await supabase.storage
  //   .from('profile-images')
  //   .upload('user-${userId}/profile.jpg', imageBytes);
}
```

### 3. 인증 시스템
**파일**: `lib/features/auth/presentation/widgets/login_modal.dart`
```dart
// 현재: 시뮬레이션 로그인
void _login() async {
  // 시뮬레이션 코드 삭제
  Navigator.of(context).pop(true);
  
  // 수정 필요: Supabase Auth
  // final response = await supabase.auth.signInWithPassword(
  //   email: _emailController.text,
  //   password: _passwordController.text,
  // );
}
```

### 4. 데이터 페칭
**파일**: `lib/features/home/presentation/widgets/home_tab.dart`
```dart
// 현재: 정적 데이터
List<Map<String, dynamic>> _feedData = [...];

// 수정 필요: 실시간 데이터 페칭
// @override
// void initState() {
//   super.initState();
//   _loadFeeds();
// }
// 
// Future<void> _loadFeeds() async {
//   final feeds = await supabase
//     .from('feeds')
//     .select()
//     .order('created_at', ascending: false);
//   setState(() {
//     _feedData = feeds;
//   });
// }
```

## 🔒 보안 강화가 필요한 코드

### 1. 인증 토큰 관리
**현재**: SharedPreferences에 민감한 데이터 저장
**보안 강화 필요**:

```dart
// 현재 (보안 위험)
await prefs.setString('authToken', token);

// 수정 필요: 안전한 토큰 저장
// await secureStorage.write(key: 'authToken', value: token);
```

**필요한 패키지**: `flutter_secure_storage`

### 2. API 키 보호
**파일**: `lib/core/config/` (새로 생성 필요)
```dart
// 현재: 하드코딩된 API 키 (위험)
const String supabaseUrl = 'https://your-project.supabase.co';
const String supabaseAnonKey = 'your-anon-key';

// 수정 필요: 환경 변수 사용
// const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
// const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
```

### 3. 입력 검증 강화
**파일**: 모든 폼 위젯들
```dart
// 현재: 기본 검증
validator: (value) {
  if (value == null || value.isEmpty) {
    return '필수 입력 항목입니다';
  }
  return null;
}

// 수정 필요: 강화된 검증
validator: (value) {
  if (value == null || value.isEmpty) {
    return '필수 입력 항목입니다';
  }
  if (value.length < 2) {
    return '최소 2자 이상 입력해주세요';
  }
  if (value.length > 50) {
    return '최대 50자까지 입력 가능합니다';
  }
  // XSS 방지
  if (value.contains('<script>') || value.contains('javascript:')) {
    return '허용되지 않는 문자가 포함되어 있습니다';
  }
  return null;
}
```

### 4. 파일 업로드 보안
**파일**: `lib/features/home/presentation/widgets/profile_edit_modal.dart`
```dart
// 현재: 파일 크기 제한만 있음
final XFile? image = await _picker.pickImage(
  maxWidth: 300,
  maxHeight: 300,
  imageQuality: 80,
);

// 수정 필요: 파일 타입 및 보안 검증
Future<void> _uploadSecureImage() async {
  final XFile? image = await _picker.pickImage(
    maxWidth: 300,
    maxHeight: 300,
    imageQuality: 80,
  );
  
  if (image != null) {
    // 파일 크기 검증
    final File file = File(image.path);
    final int fileSize = await file.length();
    if (fileSize > 5 * 1024 * 1024) { // 5MB 제한
      throw Exception('파일 크기가 너무 큽니다');
    }
    
    // 파일 타입 검증
    final String extension = image.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      throw Exception('지원하지 않는 파일 형식입니다');
    }
    
    // 바이러스 스캔 (선택사항)
    // await virusScan(file);
  }
}
```

## 📦 새로 추가해야 할 패키지들

### 1. 보안 관련
```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
  crypto: ^3.0.3
```

### 2. 상태 관리
```yaml
dependencies:
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
```

### 3. 네트워킹
```yaml
dependencies:
  supabase_flutter: ^2.3.4
  http: ^1.1.0
```

### 4. 유틸리티
```yaml
dependencies:
  image: ^4.1.3
  path: ^1.8.3
```

## 🔄 마이그레이션 계획

### Phase 1: 인프라 구축
1. Supabase 프로젝트 설정
2. 데이터베이스 스키마 설계
3. 보안 패키지 추가

### Phase 2: 인증 시스템
1. Supabase Auth 연동
2. 보안 토큰 관리 구현
3. 로그인/회원가입 API 연동

### Phase 3: 데이터 연동
1. 피드 데이터 API 연동
2. 프로필 데이터 API 연동
3. 실시간 업데이트 구현

### Phase 4: 파일 업로드
1. Supabase Storage 연동
2. 이미지 업로드 보안 강화
3. 파일 관리 시스템 구축

### Phase 5: 실시간 기능
1. 실시간 채팅 구현
2. 실시간 피드 업데이트
3. 푸시 알림 시스템

## ⚠️ 주의사항

### 1. 데이터 마이그레이션
- SharedPreferences 데이터를 Supabase로 마이그레이션
- 사용자 동의 필요
- 데이터 손실 방지

### 2. 호환성
- 기존 사용자 경험 유지
- 점진적 마이그레이션
- 롤백 계획 수립

### 3. 성능
- 이미지 최적화
- 캐싱 전략
- 네트워크 효율성

---

**마지막 업데이트**: 2025년 8월
**상태**: 백엔드 연동 준비 완료 