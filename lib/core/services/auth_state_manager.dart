import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart'; // Added for BuildContext
import 'profile_image_manager.dart'; // Added for ProfileImageManager

class AuthStateManager {
  static AuthStateManager? _instance;
  static AuthStateManager get instance => _instance ??= AuthStateManager._internal();
  
  AuthStateManager._internal();

  bool _isLoggedIn = false;
  String _userName = 'JamMaster';
  String _userNickname = 'jammaster';
  String _userBio = '재즈와 팝을 사랑하는 음악인입니다 🎵';
  String _userInstruments = '기타, 피아노';
  Uint8List? _profileImageBytes;
  String? _profileImageName;

  // 상태 변화 콜백 리스트
  final List<Function()> _stateChangeCallbacks = [];

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userNickname => _userNickname;
  String get userBio => _userBio;
  String get userInstruments => _userInstruments;
  Uint8List? get profileImageBytes => _profileImageBytes;
  String? get profileImageName => _profileImageName;

  /// 상태 변화 리스너 추가
  void addStateChangeListener(Function() callback) {
    _stateChangeCallbacks.add(callback);
  }

  /// 상태 변화 리스너 제거
  void removeStateChangeListener(Function() callback) {
    _stateChangeCallbacks.remove(callback);
  }

  /// 상태 변화 알림
  void _notifyStateChange() {
    print('🔍 상태 변화 알림 - isLoggedIn: $_isLoggedIn, userName: $_userName');
    for (final callback in _stateChangeCallbacks) {
      callback();
    }
  }

  /// 인증 상태 초기화
  Future<void> initializeAuthState() async {
    try {
      print('🔍 AuthStateManager 초기화 시작');
      
      // 1. SharedPreferences에서 사용자 정보 확인
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final userEmail = prefs.getString('userEmail');
      final userName = prefs.getString('userName');
      
      print('🔍 SharedPreferences 로그인 상태: $isLoggedIn');
      print('🔍 저장된 사용자 이메일: $userEmail');
      print('🔍 저장된 사용자 이름: $userName');
      
      // 2. ProfileImageManager는 main.dart에서 이미 초기화됨
      print('🔄 ProfileImageManager 이미 초기화됨');
      
      // 3. testuser 자동 로그인 복원 로직
      bool shouldRestoreLogin = false;
      
      // 3-1. 명시적으로 로그인 상태가 true인 경우
      if (isLoggedIn && userEmail != null) {
        shouldRestoreLogin = true;
        print('✅ 명시적 로그인 상태 복원: $userEmail');
      }
      // 3-2. 로그인 상태가 false이지만 testuser 정보가 있는 경우 (자동 복원)
      else if (userEmail == 'test@example.com' || userName != null) {
        shouldRestoreLogin = true;
        print('🔄 testuser 자동 로그인 복원 시작: ${userEmail ?? userName}');
        
        // testuser 로그인 상태 자동 복원
        await prefs.setBool('isLoggedIn', true);
        if (userEmail == null) {
          await prefs.setString('userEmail', 'test@example.com');
        }
        if (prefs.getString('userId') == null) {
          await prefs.setString('userId', 'testuser');
        }
      }
      
      // 4. 로그인 상태 처리
      if (shouldRestoreLogin) {
        // 기존 프로필 데이터 로드 (덮어쓰지 않도록)
        final restoredUserName = prefs.getString('userName') ?? 'testuser';
        final userNickname = prefs.getString('userNickname') ?? 'testuser';
        final userBio = prefs.getString('userBio') ?? '음악을 사랑하는 testuser입니다 🎵';
        final userInstruments = prefs.getString('userInstruments') ?? '기타, 피아노';
        
        // 프로필 데이터 업데이트 (기존 데이터 보존)
        _userName = restoredUserName;
        _userNickname = userNickname;
        _userBio = userBio;
        _userInstruments = userInstruments;
        _isLoggedIn = true;
        
        // 프로필 이미지 동기화 (ProfileImageManager에서 가져오기)
        final profileImageBytes = ProfileImageManager.instance.getCurrentUserProfileImage();
        if (profileImageBytes != null) {
          _profileImageBytes = profileImageBytes;
          print('✅ AuthStateManager 프로필 이미지 동기화 완료: ${(profileImageBytes.length / 1024).toStringAsFixed(1)}KB');
        } else {
          print('❌ AuthStateManager에서 프로필 이미지 없음');
        }
        
        print('✅ 로그인 상태 복원됨: $restoredUserName (이미지: ${_profileImageName ?? '없음'})');
      } else {
        // 완전히 새로운 사용자 - 로그아웃 상태
        _isLoggedIn = false;
        print('❌ 새로운 사용자, 로그아웃 상태로 설정');
      }
      
      // 5. 상태 변화 알림
      _notifyStateChange();
      
      print('✅ 인증 상태 초기화 완료 (프로필 데이터 보존)');
    } catch (e) {
      print('❌ AuthStateManager 초기화 실패: $e');
      _isLoggedIn = false;
      _notifyStateChange();
    }
  }

  /// 로그인 성공 시 상태 업데이트
  Future<void> updateLoginState({
    required String userId,
    required String email,
    String? nickname,
  }) async {
    print('🔍 로그인 상태 업데이트 시작');
    
    final prefs = await SharedPreferences.getInstance();
    final userName = nickname ?? email.split('@')[0];
    
    // 기존 프로필 데이터 로드 (있는 경우)
    final existingUserName = prefs.getString('userName');
    final existingUserNickname = prefs.getString('userNickname');
    final existingUserBio = prefs.getString('userBio');
    final existingUserInstruments = prefs.getString('userInstruments');
    final existingProfileImageName = prefs.getString('profileImageName');
    
    // 상태 업데이트 (기존 데이터가 있으면 보존, 없으면 기본값 사용)
    _isLoggedIn = true;
    _userName = existingUserName ?? userName;
    _userNickname = existingUserNickname ?? userName;
    _userBio = existingUserBio ?? '음악을 사랑하는 $userName입니다 🎵';
    _userInstruments = existingUserInstruments ?? '기타, 피아노';
    _profileImageName = existingProfileImageName;
    
    // SharedPreferences에 저장 (기존 데이터 보존)
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', userId);
    await prefs.setString('userEmail', email);
    await prefs.setString('loginTime', DateTime.now().toIso8601String());
    
    // 기존 프로필 데이터가 없을 때만 기본값 저장 (절대 덮어쓰지 않음)
    if (existingUserName == null) {
      await prefs.setString('userName', _userName);
    }
    if (existingUserNickname == null) {
      await prefs.setString('userNickname', _userNickname);
    }
    if (existingUserBio == null) {
      await prefs.setString('userBio', _userBio);
    }
    if (existingUserInstruments == null) {
      await prefs.setString('userInstruments', _userInstruments);
    }
    
    print('✅ 로그인 상태 업데이트 완료: $_userName (기존 데이터 보존됨)');
    
    // 프로필 이미지 복원
    await ProfileImageManager.instance.restoreImageOnLogin();
    
    _notifyStateChange();
  }

  /// 로그아웃 시 상태 초기화
  Future<void> logout() async {
    print('🔍 로그아웃 처리 시작');
    
    // Supabase 로그아웃
    await SupabaseService.instance.signOut();
    
    // 프로필 이미지 보존
    await ProfileImageManager.instance.preserveImageOnLogout();
    
    // 로컬 상태 초기화 (프로필 데이터는 보존)
    await _clearAuthState();
    
    print('✅ 로그아웃 완료');
    _notifyStateChange();
  }

  /// 인증 상태 완전 초기화 - SharedPreferences 상태 진단 추가
  Future<void> _clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 🧪 로그아웃 전 SharedPreferences 상태 확인
    final allKeysBefore = prefs.getKeys();
    final appStateKeysBefore = allKeysBefore.where((key) => key.startsWith('app_state_')).toList();
    final authKeysBefore = allKeysBefore.where((key) => ['isLoggedIn', 'userId', 'userEmail', 'loginTime'].contains(key)).toList();
    final profileKeysBefore = allKeysBefore.where((key) => ['userName', 'userNickname', 'userBio', 'userInstruments', 'profileImageName'].contains(key)).toList();
    
    print('🔍 로그아웃 전 상태:');
    print('  - 앱 상태 키들: $appStateKeysBefore (${appStateKeysBefore.length}개)');
    print('  - 인증 키들: $authKeysBefore (${authKeysBefore.length}개)');
    print('  - 프로필 키들: $profileKeysBefore (${profileKeysBefore.length}개)');
    
    // 로그인 상태만 초기화하고 프로필 데이터는 보존
    _isLoggedIn = false;
    
    // 프로필 데이터는 보존 (로그아웃 시에도 유지)
    // _userName, _userNickname, _userBio, _userInstruments, _profileImageBytes는 그대로 유지
    
    // SharedPreferences에서 로그인 관련 데이터만 제거
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userId');
    await prefs.remove('userEmail');
    await prefs.remove('loginTime');
    
    // 프로필 데이터는 삭제하지 않음 (보존)
    // await prefs.remove('userName');
    // await prefs.remove('userNickname');
    // await prefs.remove('userBio');
    // await prefs.remove('userInstruments');
    // await prefs.remove('profileImageName');
    
    // 🧪 로그아웃 후 SharedPreferences 상태 확인
    final allKeysAfter = prefs.getKeys();
    final appStateKeysAfter = allKeysAfter.where((key) => key.startsWith('app_state_')).toList();
    final authKeysAfter = allKeysAfter.where((key) => ['isLoggedIn', 'userId', 'userEmail', 'loginTime'].contains(key)).toList();
    final profileKeysAfter = allKeysAfter.where((key) => ['userName', 'userNickname', 'userBio', 'userInstruments', 'profileImageName'].contains(key)).toList();
    
    print('🔍 로그아웃 후 상태:');
    print('  - 앱 상태 키들: $appStateKeysAfter (${appStateKeysAfter.length}개)');
    print('  - 인증 키들: $authKeysAfter (${authKeysAfter.length}개)');
    print('  - 프로필 키들: $profileKeysAfter (${profileKeysAfter.length}개)');
    
    // 🧪 AppState 키들이 보존되었는지 확인
    if (appStateKeysBefore.length == appStateKeysAfter.length) {
      print('✅ AppState 키들이 로그아웃 후에도 보존됨 (${appStateKeysAfter.length}개)');
    } else {
      print('❌ AppState 키가 손실됨: ${appStateKeysBefore.length} → ${appStateKeysAfter.length}');
      print('❌ 손실된 키들: ${appStateKeysBefore.toSet().difference(appStateKeysAfter.toSet())}');
    }
    
    print('✅ 인증 상태 초기화 완료 (프로필 데이터 보존)');
  }

  /// 프로필 이미지 업데이트
  Future<void> updateProfileImage(Uint8List? imageBytes, String? imageName) async {
    print('🔍 프로필 이미지 업데이트 시작');
    
    _profileImageBytes = imageBytes;
    _profileImageName = imageName;
    
    // SharedPreferences에 이미지 정보 저장 (실제 바이트는 저장하지 않고 파일명만)
    final prefs = await SharedPreferences.getInstance();
    if (imageName != null) {
      await prefs.setString('profileImageName', imageName);
    } else {
      await prefs.remove('profileImageName');
    }
    
    print('✅ 프로필 이미지 업데이트 완료: $imageName');
    _notifyStateChange();
  }

  /// 프로필 데이터 저장
  Future<void> saveProfileData({
    required String name,
    required String nickname,
    required String bio,
    required String instruments,
  }) async {
    print('🔍 프로필 데이터 저장 시작');
    
    final prefs = await SharedPreferences.getInstance();
    
    // 상태 업데이트
    _userName = name;
    _userNickname = nickname;
    _userBio = bio;
    _userInstruments = instruments;
    
    // SharedPreferences에 저장
    await prefs.setString('userName', name);
    await prefs.setString('userNickname', nickname);
    await prefs.setString('userBio', bio);
    await prefs.setString('userInstruments', instruments);
    
    print('✅ 프로필 데이터 저장 완료: $name');
  }

  /// 현재 상태 정보 출력 (디버깅용)
  void printCurrentState() {
    print('🔍 현재 인증 상태:');
    print('  - isLoggedIn: $_isLoggedIn');
    print('  - userName: $_userName');
    print('  - userNickname: $_userNickname');
    print('  - userBio: $_userBio');
    print('  - userInstruments: $_userInstruments');
    print('  - profileImageName: $_profileImageName');
  }

  /// 로그인 필요 여부 확인
  bool get requiresLogin => !_isLoggedIn;

  /// 로그인 필요 메시지 표시
  void showLoginRequiredMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.login, color: Colors.white),
            SizedBox(width: 8),
            Text('로그인 또는 회원가입이 필요합니다.'),
          ],
        ),
        backgroundColor: const Color(0xFFFF6B9D),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '로그인',
          textColor: Colors.white,
          onPressed: () {
            // 로그인 모달 표시 로직은 각 위젯에서 처리
          },
        ),
      ),
    );
  }
} 