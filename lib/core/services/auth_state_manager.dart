import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart'; // Added for BuildContext
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
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
  String? _avatarUrl;

  // Supabase auth 스트림 구독
  StreamSubscription<AuthState>? _authSubscription;

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
  String? get avatarUrl => _avatarUrl;

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
    for (final callback in _stateChangeCallbacks) {
      callback();
    }
  }

  /// 인증 상태 초기화
  Future<void> initializeAuthState() async {
    try {

      // 1. Supabase 세션 확인 (진짜 인증 소스)
      final currentUser = SupabaseService.instance.currentUser;

      if (currentUser != null) {
        // Supabase 세션이 있으면 로그인 상태 복원
        final prefs = await SharedPreferences.getInstance();

        _isLoggedIn = true;
        _userName = prefs.getString('userName') ?? currentUser.email?.split('@')[0] ?? 'User';
        _userNickname = prefs.getString('userNickname') ?? _userName;
        _userBio = prefs.getString('userBio') ?? '음악을 사랑합니다 🎵';
        _userInstruments = prefs.getString('userInstruments') ?? '기타, 피아노';

        // SharedPreferences 동기화 (세션이 유효하므로 로그인 상태 저장)
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', currentUser.id);
        await prefs.setString('userEmail', currentUser.email ?? '');

        // 프로필 이미지 동기화
        final profileImageBytes = ProfileImageManager.instance.getCurrentUserProfileImage();
        if (profileImageBytes != null) {
          _profileImageBytes = profileImageBytes;
        }

      } else {
        // Supabase 세션 없음 → 로그아웃 상태
        _isLoggedIn = false;

        // SharedPreferences의 로그인 상태도 초기화
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false);
        await prefs.remove('userId');

      }

      // Supabase 프로필 동기화 (비동기, 논블로킹)
      _loadProfileFromSupabase().then((_) => _notifyStateChange()).catchError((_) {});

      // Supabase auth 이벤트 구독 (토큰 갱신, 외부 로그아웃 등 처리)
      _authSubscription?.cancel();
      _authSubscription = SupabaseService.instance.client.auth.onAuthStateChange.listen(
        (data) async {
          switch (data.event) {
            case AuthChangeEvent.signedOut:
              if (_isLoggedIn) {
                await _clearAuthState();
                _notifyStateChange();
              }
            case AuthChangeEvent.tokenRefreshed:
              // 세션 토큰 갱신 — 별도 상태 변경 불필요
              break;
            default:
              break;
          }
        },
      );

      _notifyStateChange();
    } catch (e) {
      _isLoggedIn = false;
      _notifyStateChange();
    }
  }

  /// Supabase profiles 테이블에서 프로필 로드 → 로컬 상태 동기화
  Future<void> _loadProfileFromSupabase() async {
    final currentUser = SupabaseService.instance.currentUser;
    if (currentUser == null) return;

    try {
      final profile = await SupabaseService.instance.getUserProfile(currentUser.id);
      if (profile == null) return;

      final prefs = await SharedPreferences.getInstance();

      if (profile['nickname'] != null) {
        _userName = profile['nickname'] as String;
        await prefs.setString('userName', _userName);
      }
      if (profile['username'] != null) {
        _userNickname = profile['username'] as String;
        await prefs.setString('userNickname', _userNickname);
      }
      if (profile['bio'] != null) {
        _userBio = profile['bio'] as String;
        await prefs.setString('userBio', _userBio);
      }
      if (profile['instruments'] != null) {
        _userInstruments = profile['instruments'] as String;
        await prefs.setString('userInstruments', _userInstruments);
      }
      _avatarUrl = profile['avatar_url'] as String?;
      if (_avatarUrl != null) {
        await prefs.setString('avatarUrl', _avatarUrl!);
      }
    } catch (_) {
      // 네트워크 오류 시 로컬 캐시 데이터 유지
    }
  }

  /// 아바타 URL 업데이트 (Storage 업로드 후 호출)
  Future<void> updateAvatarUrl(String? url) async {
    _avatarUrl = url;
    final prefs = await SharedPreferences.getInstance();
    if (url != null) {
      await prefs.setString('avatarUrl', url);
    } else {
      await prefs.remove('avatarUrl');
    }
    _notifyStateChange();
  }

  /// 로그인 성공 시 상태 업데이트
  Future<void> updateLoginState({
    required String userId,
    required String email,
    String? nickname,
  }) async {
    
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
    
    
    // 프로필 이미지 복원
    await ProfileImageManager.instance.restoreImageOnLogin();

    // Supabase 프로필 동기화 (비동기, 논블로킹)
    _loadProfileFromSupabase().then((_) => _notifyStateChange()).catchError((_) {});

    _notifyStateChange();
  }

  /// 로그아웃 시 상태 초기화
  Future<void> logout() async {
    
    // Supabase 로그아웃
    await SupabaseService.instance.signOut();
    
    // 프로필 이미지 보존
    await ProfileImageManager.instance.preserveImageOnLogout();
    
    // 로컬 상태 초기화 (프로필 데이터는 보존)
    await _clearAuthState();
    
    _notifyStateChange();
  }

  /// 인증 상태 완전 초기화 - SharedPreferences 상태 진단 추가
  Future<void> _clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    
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
    
  }

  /// 프로필 이미지 업데이트
  Future<void> updateProfileImage(Uint8List? imageBytes, String? imageName) async {
    
    _profileImageBytes = imageBytes;
    _profileImageName = imageName;
    
    // SharedPreferences에 이미지 정보 저장 (실제 바이트는 저장하지 않고 파일명만)
    final prefs = await SharedPreferences.getInstance();
    if (imageName != null) {
      await prefs.setString('profileImageName', imageName);
    } else {
      await prefs.remove('profileImageName');
    }
    
    _notifyStateChange();
  }

  /// 프로필 데이터 저장
  Future<void> saveProfileData({
    required String name,
    required String nickname,
    required String bio,
    required String instruments,
  }) async {
    
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

    // Supabase 동기화
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId != null) {
      try {
        await SupabaseService.instance.updateUserProfile(
          userId: userId,
          profileData: {
            'nickname': name,
            'username': nickname,
            'bio': bio,
            'instruments': instruments,
          },
        );
      } catch (_) {
        // Supabase 동기화 실패 시 로컬 저장은 유지
      }
    }
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