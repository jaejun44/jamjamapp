import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'auth_state_manager.dart';
import 'supabase_service.dart';

/// 프로필 이미지 관리 서비스
/// 이미지 업로드, 저장, 로드, 캐싱을 담당
class ProfileImageManager {
  static final ProfileImageManager _instance = ProfileImageManager._internal();
  factory ProfileImageManager() => _instance;
  ProfileImageManager._internal();

  static ProfileImageManager get instance => _instance;

  // 이미지 캐시
  final Map<String, Uint8List> _imageCache = <String, Uint8List>{};
  
  // 콜백 리스트
  final List<Function(Uint8List?)> _imageChangeCallbacks = [];

  /// 이미지 변경 콜백 등록
  void addImageChangeCallback(Function(Uint8List?) callback) {
    _imageChangeCallbacks.add(callback);
  }

  /// 이미지 변경 콜백 제거
  void removeImageChangeCallback(Function(Uint8List?) callback) {
    _imageChangeCallbacks.remove(callback);
  }

  /// 이미지 변경 알림
  void _notifyImageChange(Uint8List? imageBytes) {
    for (final callback in _imageChangeCallbacks) {
      callback(imageBytes);
    }
  }

  /// 프로필 이미지 로드
  Future<Uint8List?> loadProfileImage() async {
    try {
      
      final prefs = await SharedPreferences.getInstance();
      final imageData = prefs.getString('user_profile_image_data');
      
      if (imageData != null && imageData.isNotEmpty) {
        try {
          // Base64 디코딩
          final imageBytes = base64Decode(imageData);
          
          // 이미지 유효성 검사
          if (isValidImage(imageBytes)) {
            // 캐시에 저장
            _imageCache['current_user'] = imageBytes;
            
            return imageBytes;
          } else {
            // 손상된 데이터 삭제
            await prefs.remove('user_profile_image_data');
            return null;
          }
        } catch (e) {
          // 손상된 데이터 삭제
          await prefs.remove('user_profile_image_data');
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// 프로필 이미지 저장
  Future<void> saveProfileImage(Uint8List imageBytes) async {
    try {
      
      // 1. 이미지 유효성 검사
      if (!isValidImage(imageBytes)) {
        throw Exception('유효하지 않은 이미지입니다.');
      }
      
      // 2. 이미지 압축 및 최적화
      final compressedBytes = await compressImage(imageBytes);
      final optimizedBytes = await resizeImage(compressedBytes);
      
      // 3. SharedPreferences에 저장 (더 명확한 키 사용)
      final prefs = await SharedPreferences.getInstance();
      final imageData = base64Encode(optimizedBytes);
      
      
      // 웹 환경 저장소 제한 대응 (localStorage는 보통 5-10MB 제한)
      if (imageData.length > 2 * 1024 * 1024) { // 2MB Base64 제한
        throw Exception('이미지가 너무 큽니다. 더 작은 이미지를 선택해주세요.');
      }
      
      await prefs.setString('user_profile_image_data', imageData);
      
      // 4. 캐시에 저장
      _imageCache['current_user'] = optimizedBytes;

      // 5. AuthStateManager 업데이트
      AuthStateManager.instance.updateProfileImage(optimizedBytes, 'profile_image.jpg');

      // 6. Supabase Storage 업로드 (비동기, 논블로킹)
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId != null) {
        SupabaseService.instance
            .uploadAvatar(userId: userId, imageBytes: optimizedBytes)
            .then((avatarUrl) async {
          await SupabaseService.instance.updateUserProfile(
            userId: userId,
            profileData: {'avatar_url': avatarUrl},
          );
          await AuthStateManager.instance.updateAvatarUrl(avatarUrl);
        }).catchError((_) {
          // 업로드 실패 시 로컬 이미지는 유지
        });
      }

      // 7. 이미지 변경 알림
      _notifyImageChange(optimizedBytes);
      
      
      // 8. 저장 확인
      final savedData = prefs.getString('user_profile_image_data');
      if (savedData != null && savedData.isNotEmpty) {
      } else {
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 프로필 이미지 삭제
  Future<void> deleteProfileImage() async {
    try {
      
      // 1. SharedPreferences에서 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile_image_data');
      
      // 2. 캐시에서 삭제
      _imageCache.remove('current_user');
      
      // 3. AuthStateManager 업데이트
      AuthStateManager.instance.updateProfileImage(null, null);
      
      // 4. 이미지 변경 알림
      _notifyImageChange(null);
      
    } catch (e) {
      rethrow;
    }
  }

  /// 이미지 압축
  Future<Uint8List> compressImage(Uint8List imageBytes) async {
    try {
      // 이미지 크기가 1MB 이하면 압축하지 않음
      if (imageBytes.length <= 1024 * 1024) {
        return imageBytes;
      }
      
      // 크기 제한 적용
      if (imageBytes.length > 5 * 1024 * 1024) { // 5MB 제한
        throw Exception('이미지 크기가 너무 큽니다. 5MB 이하의 이미지를 선택해주세요.');
      }
      
      // 간단한 압축 시뮬레이션 (실제로는 flutter_image_compress 라이브러리 사용)
      // 현재는 원본 이미지를 반환하되, 크기 정보 로깅
      
      return imageBytes;
    } catch (e) {
      rethrow;
    }
  }

  /// 이미지 크기 조정
  Future<Uint8List> resizeImage(Uint8List imageBytes, {int maxWidth = 400, int maxHeight = 400}) async {
    try {
      // 간단한 크기 조정 시뮬레이션
      // 실제로는 flutter_image 라이브러리 사용
      
      return imageBytes;
    } catch (e) {
      rethrow;
    }
  }

  /// 이미지 유효성 검사
  bool isValidImage(Uint8List imageBytes) {
    try {
      // 1. 기본적인 크기 검사
      if (imageBytes.isEmpty) {
        return false;
      }
      
      if (imageBytes.length > 10 * 1024 * 1024) { // 10MB 제한
        return false;
      }
      
      // 2. 최소 크기 검사 (너무 작은 이미지 방지)
      if (imageBytes.length < 1024) { // 1KB 미만
        return false;
      }
      
      // 3. 이미지 형식 검사 (간단한 헤더 검사)
      if (imageBytes.length >= 2) {
        final header = imageBytes.take(2).toList();
        
        // JPEG: FF D8
        if (header[0] == 0xFF && header[1] == 0xD8) {
          return true;
        }
        
        // PNG: 89 50
        if (header[0] == 0x89 && header[1] == 0x50) {
          return true;
        }
        
        // GIF: 47 49
        if (header[0] == 0x47 && header[1] == 0x49) {
          return true;
        }
        
        // WebP: 52 49
        if (header[0] == 0x52 && header[1] == 0x49) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 캐시된 이미지 가져오기
  Uint8List? getCachedImage(String key) {
    return _imageCache[key];
  }

  /// 캐시 클리어
  void clearCache() {
    _imageCache.clear();
  }

  /// 현재 사용자의 프로필 이미지 가져오기
  Uint8List? getCurrentUserProfileImage() {
    try {
      // 1. 캐시에서 확인
      final cachedImage = _imageCache['current_user'];
      if (cachedImage != null && cachedImage.isNotEmpty) {
        return cachedImage;
      }
      
      // 2. AuthStateManager에서 확인
      final authImage = AuthStateManager.instance.profileImageBytes;
      if (authImage != null && authImage.isNotEmpty) {
        // 캐시에 저장
        _imageCache['current_user'] = authImage;
        return authImage;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 프로필 이미지 위젯 생성
  Widget buildProfileImage({
    double radius = 20,
    Color? backgroundColor,
    Widget? placeholder,
  }) {
    // 1. 캐시에서 이미지 확인
    Uint8List? imageBytes = getCurrentUserProfileImage();
    
    // 2. 캐시에 없으면 AuthStateManager에서 확인
    if (imageBytes == null) {
      imageBytes = AuthStateManager.instance.profileImageBytes;
      if (imageBytes != null) {
        // 캐시에 저장
        _imageCache['current_user'] = imageBytes;
      }
    }
    
    // 3. 디버깅 로그
    if (imageBytes != null) {
    } else {
    }
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppTheme.accentPink,
      backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
      child: imageBytes == null 
          ? (placeholder ?? const Icon(Icons.person, color: AppTheme.white))
          : null,
    );
  }

  /// 로그아웃 시 이미지 보존 (삭제하지 않음)
  Future<void> preserveImageOnLogout() async {
    // 로그아웃 시에도 이미지는 보존
    // 캐시와 SharedPreferences의 이미지 데이터는 그대로 유지
  }

  /// 로그인 시 이미지 복원
  Future<void> restoreImageOnLogin() async {
    try {
      
      // 1. SharedPreferences에서 이미지 로드
      final imageBytes = await loadProfileImage();
      
      if (imageBytes != null) {
        // 2. 캐시에 저장
        _imageCache['current_user'] = imageBytes;
        
        // 3. AuthStateManager 업데이트
        AuthStateManager.instance.updateProfileImage(imageBytes, 'profile_image.jpg');
        
        // 4. 이미지 변경 알림
        _notifyImageChange(imageBytes);
        
      } else {
      }
    } catch (e) { // ignore: empty_catches
    }
  }

  /// 초기화
  Future<void> initialize() async {
    try {
      
      // 1. SharedPreferences에서 이미지 로드
      final prefs = await SharedPreferences.getInstance();
      final imageData = prefs.getString('user_profile_image_data');
      
      
      if (imageData != null && imageData.isNotEmpty) {
        try {
          // Base64 디코딩
          final imageBytes = base64Decode(imageData);
          
          // 이미지 유효성 검사
          if (isValidImage(imageBytes)) {
            // 캐시에 저장
            _imageCache['current_user'] = imageBytes;
            
            // AuthStateManager 동기화
            AuthStateManager.instance.updateProfileImage(imageBytes, 'profile_image.jpg');
            
          } else {
            // 손상된 데이터 삭제
            await prefs.remove('user_profile_image_data');
          }
        } catch (e) {
          // 손상된 데이터 삭제
          await prefs.remove('user_profile_image_data');
        }
      } else {
      }
      
      // 2. AuthStateManager에서 이미지 복원 시도
      final authImageBytes = AuthStateManager.instance.profileImageBytes;
      if (authImageBytes != null && authImageBytes.isNotEmpty) {
        // 캐시에 저장
        _imageCache['current_user'] = authImageBytes;
      } else {
      }
      
    } catch (e) { // ignore: empty_catches
    }
  }
} 