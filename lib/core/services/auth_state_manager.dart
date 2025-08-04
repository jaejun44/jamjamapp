import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart'; // Added for BuildContext

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

  /// 앱 시작 시 로그인 상태 초기화
  Future<void> initializeAuthState() async {
    print('🔍 AuthStateManager 초기화 시작');
    
    // 1. SharedPreferences에서 로그인 상태 확인
    final prefs = await SharedPreferences.getInstance();
    final savedIsLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    print('🔍 SharedPreferences 로그인 상태: $savedIsLoggedIn');
    
    if (savedIsLoggedIn) {
      // 2. Supabase 인증 상태 확인
      final supabaseUser = SupabaseService.instance.currentUser;
      print('🔍 Supabase 현재 사용자: ${supabaseUser?.id}');
      
      if (supabaseUser != null) {
        // 3. SharedPreferences에서 사용자 정보 로드
        _isLoggedIn = true;
        _userName = prefs.getString('userName') ?? 'JamMaster';
        _userNickname = prefs.getString('userNickname') ?? 'jammaster';
        _userBio = prefs.getString('userBio') ?? '재즈와 팝을 사랑하는 음악인입니다 🎵';
        _userInstruments = prefs.getString('userInstruments') ?? '기타, 피아노';
        _profileImageName = prefs.getString('profileImageName');
        
        print('✅ 로그인 상태 복원됨: $_userName (이미지: $_profileImageName)');
        _notifyStateChange();
      } else {
        // Supabase 인증이 없으면 로그아웃 처리
        print('❌ Supabase 인증 없음, 로그아웃 처리');
        await _clearAuthState();
      }
    } else {
      print('❌ 로그인되지 않은 상태');
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
    _notifyStateChange();
  }

  /// 로그아웃 시 상태 초기화
  Future<void> logout() async {
    print('🔍 로그아웃 처리 시작');
    
    // Supabase 로그아웃
    await SupabaseService.instance.signOut();
    
    // 로컬 상태 초기화
    await _clearAuthState();
    
    print('✅ 로그아웃 완료');
    _notifyStateChange();
  }

  /// 인증 상태 완전 초기화
  Future<void> _clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 로컬 상태 초기화
    _isLoggedIn = false;
    _userName = 'JamMaster';
    _userNickname = 'jammaster';
    _userBio = '재즈와 팝을 사랑하는 음악인입니다 🎵';
    _userInstruments = '기타, 피아노';
    _profileImageBytes = null;
    _profileImageName = null;
    
    // SharedPreferences 초기화
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userNickname');
    await prefs.remove('userEmail');
    await prefs.remove('userBio');
    await prefs.remove('userInstruments');
    await prefs.remove('loginTime');
    await prefs.remove('profileImageName');
    
    print('✅ 인증 상태 초기화 완료');
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