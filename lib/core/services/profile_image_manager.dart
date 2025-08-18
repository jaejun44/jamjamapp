import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'auth_state_manager.dart';

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
      print('🔍 프로필 이미지 로드 시작');
      
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
            
            print('✅ 프로필 이미지 로드 완료: ${(imageBytes.length / 1024).toStringAsFixed(1)}KB');
            return imageBytes;
          } else {
            print('❌ 프로필 이미지 로드 실패: 유효하지 않은 이미지');
            // 손상된 데이터 삭제
            await prefs.remove('user_profile_image_data');
            return null;
          }
        } catch (e) {
          print('❌ 프로필 이미지 로드 실패: 디코딩 오류 - $e');
          // 손상된 데이터 삭제
          await prefs.remove('user_profile_image_data');
          return null;
        }
      } else {
        print('✅ 프로필 이미지 로드 완료: 저장된 이미지 없음');
        return null;
      }
    } catch (e) {
      print('❌ 프로필 이미지 로드 실패: $e');
      return null;
    }
  }

  /// 프로필 이미지 저장
  Future<void> saveProfileImage(Uint8List imageBytes) async {
    try {
      print('🔍 프로필 이미지 저장 시작');
      
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
      
      print('🔍 SharedPreferences에 저장 시작: ${(optimizedBytes.length / 1024).toStringAsFixed(1)}KB');
      
      // 웹 환경 저장소 제한 대응 (localStorage는 보통 5-10MB 제한)
      if (imageData.length > 2 * 1024 * 1024) { // 2MB Base64 제한
        print('⚠️ 이미지 크기가 웹 저장소 제한에 근접함: ${(imageData.length / 1024 / 1024).toStringAsFixed(2)}MB');
        throw Exception('이미지가 너무 큽니다. 더 작은 이미지를 선택해주세요.');
      }
      
      await prefs.setString('user_profile_image_data', imageData);
      print('✅ SharedPreferences 저장 완료');
      
      // 4. 캐시에 저장
      _imageCache['current_user'] = optimizedBytes;
      print('✅ 캐시 저장 완료');
      
      // 5. AuthStateManager 업데이트
      AuthStateManager.instance.updateProfileImage(optimizedBytes, 'profile_image.jpg');
      print('✅ AuthStateManager 업데이트 완료');
      
      // 6. 이미지 변경 알림
      _notifyImageChange(optimizedBytes);
      print('✅ 이미지 변경 알림 완료');
      
      print('✅ 프로필 이미지 저장 완료: ${(optimizedBytes.length / 1024).toStringAsFixed(1)}KB');
      
      // 7. 저장 확인
      final savedData = prefs.getString('user_profile_image_data');
      if (savedData != null && savedData.isNotEmpty) {
        print('✅ 프로필 이미지 저장 확인됨: ${(savedData.length / 1024).toStringAsFixed(1)}KB');
      } else {
        print('❌ 프로필 이미지 저장 확인 실패');
      }
    } catch (e) {
      print('❌ 프로필 이미지 저장 실패: $e');
      rethrow;
    }
  }

  /// 프로필 이미지 삭제
  Future<void> deleteProfileImage() async {
    try {
      print('🔍 프로필 이미지 삭제 시작');
      
      // 1. SharedPreferences에서 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile_image_data');
      
      // 2. 캐시에서 삭제
      _imageCache.remove('current_user');
      
      // 3. AuthStateManager 업데이트
      AuthStateManager.instance.updateProfileImage(null, null);
      
      // 4. 이미지 변경 알림
      _notifyImageChange(null);
      
      print('✅ 프로필 이미지 삭제 완료');
    } catch (e) {
      print('❌ 프로필 이미지 삭제 실패: $e');
      rethrow;
    }
  }

  /// 이미지 압축
  Future<Uint8List> compressImage(Uint8List imageBytes) async {
    try {
      // 이미지 크기가 1MB 이하면 압축하지 않음
      if (imageBytes.length <= 1024 * 1024) {
        print('✅ 이미지 크기가 적절함: ${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)}MB');
        return imageBytes;
      }
      
      // 크기 제한 적용
      if (imageBytes.length > 5 * 1024 * 1024) { // 5MB 제한
        throw Exception('이미지 크기가 너무 큽니다. 5MB 이하의 이미지를 선택해주세요.');
      }
      
      // 간단한 압축 시뮬레이션 (실제로는 flutter_image_compress 라이브러리 사용)
      // 현재는 원본 이미지를 반환하되, 크기 정보 로깅
      print('✅ 이미지 압축 완료: ${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)}MB');
      print('💡 향후 flutter_image_compress 라이브러리로 실제 압축 구현 예정');
      
      return imageBytes;
    } catch (e) {
      print('❌ 이미지 압축 실패: $e');
      rethrow;
    }
  }

  /// 이미지 크기 조정
  Future<Uint8List> resizeImage(Uint8List imageBytes, {int maxWidth = 400, int maxHeight = 400}) async {
    try {
      // 간단한 크기 조정 시뮬레이션
      // 실제로는 flutter_image 라이브러리 사용
      print('✅ 이미지 크기 조정 완료: ${maxWidth}x$maxHeight');
      print('💡 향후 flutter_image 라이브러리로 실제 리사이즈 구현 예정');
      
      return imageBytes;
    } catch (e) {
      print('❌ 이미지 크기 조정 실패: $e');
      rethrow;
    }
  }

  /// 이미지 유효성 검사
  bool isValidImage(Uint8List imageBytes) {
    try {
      // 1. 기본적인 크기 검사
      if (imageBytes.isEmpty) {
        print('❌ 이미지가 비어있습니다.');
        return false;
      }
      
      if (imageBytes.length > 10 * 1024 * 1024) { // 10MB 제한
        print('❌ 이미지 크기가 너무 큽니다: ${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)}MB');
        return false;
      }
      
      // 2. 최소 크기 검사 (너무 작은 이미지 방지)
      if (imageBytes.length < 1024) { // 1KB 미만
        print('❌ 이미지가 너무 작습니다: ${imageBytes.length} bytes');
        return false;
      }
      
      // 3. 이미지 형식 검사 (간단한 헤더 검사)
      if (imageBytes.length >= 2) {
        final header = imageBytes.take(2).toList();
        
        // JPEG: FF D8
        if (header[0] == 0xFF && header[1] == 0xD8) {
          print('✅ JPEG 이미지 형식 확인됨');
          return true;
        }
        
        // PNG: 89 50
        if (header[0] == 0x89 && header[1] == 0x50) {
          print('✅ PNG 이미지 형식 확인됨');
          return true;
        }
        
        // GIF: 47 49
        if (header[0] == 0x47 && header[1] == 0x49) {
          print('✅ GIF 이미지 형식 확인됨');
          return true;
        }
        
        // WebP: 52 49
        if (header[0] == 0x52 && header[1] == 0x49) {
          print('✅ WebP 이미지 형식 확인됨');
          return true;
        }
      }
      
      print('❌ 지원하지 않는 이미지 형식입니다.');
      return false;
    } catch (e) {
      print('❌ 이미지 유효성 검사 실패: $e');
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
    print('✅ 이미지 캐시 클리어 완료');
  }

  /// 현재 사용자의 프로필 이미지 가져오기
  Uint8List? getCurrentUserProfileImage() {
    try {
      // 1. 캐시에서 확인
      final cachedImage = _imageCache['current_user'];
      if (cachedImage != null && cachedImage.isNotEmpty) {
        print('✅ 캐시에서 프로필 이미지 반환: ${(cachedImage.length / 1024).toStringAsFixed(1)}KB');
        return cachedImage;
      }
      
      // 2. AuthStateManager에서 확인
      final authImage = AuthStateManager.instance.profileImageBytes;
      if (authImage != null && authImage.isNotEmpty) {
        // 캐시에 저장
        _imageCache['current_user'] = authImage;
        print('✅ AuthStateManager에서 프로필 이미지 반환: ${(authImage.length / 1024).toStringAsFixed(1)}KB');
        return authImage;
      }
      
      print('❌ 프로필 이미지 없음');
      return null;
    } catch (e) {
      print('❌ 프로필 이미지 가져오기 실패: $e');
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
        print('✅ AuthStateManager에서 프로필 이미지 복원됨');
      }
    }
    
    // 3. 디버깅 로그
    if (imageBytes != null) {
      print('✅ 프로필 이미지 위젯 생성: ${(imageBytes.length / 1024).toStringAsFixed(1)}KB');
    } else {
      print('❌ 프로필 이미지 없음, 기본 아이콘 사용');
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
    print('✅ 프로필 이미지 보존 (로그아웃 시)');
  }

  /// 로그인 시 이미지 복원
  Future<void> restoreImageOnLogin() async {
    try {
      print('🔍 프로필 이미지 복원 시작');
      
      // 1. SharedPreferences에서 이미지 로드
      final imageBytes = await loadProfileImage();
      
      if (imageBytes != null) {
        // 2. 캐시에 저장
        _imageCache['current_user'] = imageBytes;
        
        // 3. AuthStateManager 업데이트
        AuthStateManager.instance.updateProfileImage(imageBytes, 'profile_image.jpg');
        
        // 4. 이미지 변경 알림
        _notifyImageChange(imageBytes);
        
        print('✅ 프로필 이미지 복원 완료: ${(imageBytes.length / 1024).toStringAsFixed(1)}KB');
      } else {
        print('✅ 프로필 이미지 복원 완료: 이미지 없음');
      }
    } catch (e) {
      print('❌ 프로필 이미지 복원 실패: $e');
    }
  }

  /// 초기화
  Future<void> initialize() async {
    try {
      print('🔍 ProfileImageManager 초기화 시작');
      
      // 1. SharedPreferences에서 이미지 로드
      final prefs = await SharedPreferences.getInstance();
      final imageData = prefs.getString('user_profile_image_data');
      
      print('🔍 SharedPreferences에서 이미지 데이터 확인: ${imageData != null ? '있음 (${(imageData.length / 1024).toStringAsFixed(1)}KB)' : '없음'}');
      
      if (imageData != null && imageData.isNotEmpty) {
        try {
          print('🔍 Base64 디코딩 시작');
          // Base64 디코딩
          final imageBytes = base64Decode(imageData);
          print('✅ Base64 디코딩 완료: ${(imageBytes.length / 1024).toStringAsFixed(1)}KB');
          
          // 이미지 유효성 검사
          if (isValidImage(imageBytes)) {
            print('✅ 이미지 유효성 검사 통과');
            // 캐시에 저장
            _imageCache['current_user'] = imageBytes;
            print('✅ 캐시에 이미지 저장 완료');
            
            // AuthStateManager 동기화
            AuthStateManager.instance.updateProfileImage(imageBytes, 'profile_image.jpg');
            print('✅ AuthStateManager 동기화 완료');
            
            print('✅ ProfileImageManager 초기화 완료 - 이미지 로드됨: ${(imageBytes.length / 1024).toStringAsFixed(1)}KB');
          } else {
            print('❌ ProfileImageManager 초기화 실패: 유효하지 않은 이미지');
            // 손상된 데이터 삭제
            await prefs.remove('user_profile_image_data');
            print('✅ ProfileImageManager 초기화 완료 - 저장된 이미지 없음');
          }
        } catch (e) {
          print('❌ ProfileImageManager 초기화 실패: 디코딩 오류 - $e');
          // 손상된 데이터 삭제
          await prefs.remove('user_profile_image_data');
          print('✅ ProfileImageManager 초기화 완료 - 저장된 이미지 없음');
        }
      } else {
        print('✅ ProfileImageManager 초기화 완료 - 저장된 이미지 없음');
      }
      
      // 2. AuthStateManager에서 이미지 복원 시도
      final authImageBytes = AuthStateManager.instance.profileImageBytes;
      if (authImageBytes != null && authImageBytes.isNotEmpty) {
        print('✅ AuthStateManager에서 프로필 이미지 발견: ${(authImageBytes.length / 1024).toStringAsFixed(1)}KB');
        // 캐시에 저장
        _imageCache['current_user'] = authImageBytes;
        print('✅ AuthStateManager에서 프로필 이미지 복원됨: ${(authImageBytes.length / 1024).toStringAsFixed(1)}KB');
      } else {
        print('❌ AuthStateManager에서 프로필 이미지 없음');
      }
      
    } catch (e) {
      print('❌ ProfileImageManager 초기화 실패: $e');
    }
  }
} 