import 'dart:convert';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'auth_state_manager.dart'; // AuthStateManager import 추가

/// 앱 전체 상태를 중앙 집중식으로 관리하는 매니저
class AppStateManager {
  static AppStateManager? _instance;
  static AppStateManager get instance => _instance ??= AppStateManager._internal();
  
  AppStateManager._internal();

  // 상태 변화 콜백 리스트
  final List<Function(String, dynamic)> _stateChangeCallbacks = [];

  // 앱 전체 상태
  final Map<String, dynamic> _appState = {
    // 홈 탭 상태 - 수정: List는 .empty() 팩토리 사용
    'home': {
      'likedFeeds': Map<int, bool>(), // 🔧 리터럴 대신 생성자 사용
      'savedFeeds': Map<int, bool>(), // 🔧 리터럴 대신 생성자 사용
      'followedUsers': <String>[], // 🔧 List 리터럴은 안전함
      'isPersonalizedMode': true,
      'isOfflineMode': false,
      'selectedGenre': '전체',
      'selectedMediaType': '전체',
      'searchQuery': '',
      'isRealtimeUpdateEnabled': true,
      'feedData': <Map<String, dynamic>>[], // 🔧 List 리터럴은 안전함
    },
    
    // 댓글 시스템 상태 - ChatGPT-4o 권장: 명시적 생성자 사용
    'comments': {
      'commentData': Map<String, List<Map<String, dynamic>>>(), // 🔧 리터럴 대신 생성자 사용
      'replyData': Map<String, List<Map<String, dynamic>>>(), // 🔧 리터럴 대신 생성자 사용
      'nestedReplyData': Map<String, List<Map<String, dynamic>>>(), // 🔧 리터럴 대신 생성자 사용
      'commentCounts': Map<int, int>(), // 🔧 리터럴 대신 생성자 사용
      'likeCounts': Map<int, int>(), // 🔧 리터럴 대신 생성자 사용
    },
    
    // 사용자 액션 상태 - 수정: List는 리터럴 사용
    'userActions': {
      'likedPosts': Map<int, bool>(), // 🔧 리터럴 대신 생성자 사용
      'savedPosts': Map<int, bool>(), // 🔧 리터럴 대신 생성자 사용
      'followedUsers': <String>[], // 🔧 List 리터럴은 안전함
      'userProfileImage': Map<String, dynamic>(), // 🔧 리터럴 대신 생성자 사용
    },
    
    // 검색 탭 상태 - 수정: List는 리터럴 사용
    'search': {
      'searchHistory': <String>[], // 🔧 List 리터럴은 안전함
      'favoriteSearches': <String>[], // 🔧 List 리터럴은 안전함
      'selectedGenres': <String>[], // 🔧 List 리터럴은 안전함
      'selectedInstruments': <String>[], // 🔧 List 리터럴은 안전함
      'selectedLocations': <String>[], // 🔧 List 리터럴은 안전함
      'sortBy': 'relevance',
      'sortOrder': 'desc',
      'minFollowers': null,
      'maxFollowers': null,
      'isOnline': null,
      'isVerified': null,
    },
    
    // 잼 탭 상태 - 수정: List는 리터럴 사용
    'jam': {
      'jamSessions': <Map<String, dynamic>>[], // 🔧 List 리터럴은 안전함
      'userJoinedSessions': <int>[], // 🔧 List 리터럴은 안전함
      'isRealtimeUpdateEnabled': true,
      'filterGenre': 'all',
      'filterStatus': 'all',
    },

    // 채팅 탭 상태 - 수정: List는 리터럴 사용
    'chat': {
      'mutedChats': <int>[], // 🔧 List 리터럴은 안전함
      'pinnedChats': <int>[], // 🔧 List 리터럴은 안전함
      'isRealtimeUpdateEnabled': true,
      'lastReadMessages': Map<int, String>(), // 🔧 리터럴 대신 생성자 사용
    },
    
    // 설정 상태
    'settings': {
      'notifications': true,
      'darkMode': true,
      'autoPlay': false,
      'dataSaver': false,
    },
  };

  // Getters - 모든 getter는 getState()를 사용하여 LinkedHashMap을 보장
  Map<String, dynamic> get homeState => getState('home');
  Map<String, dynamic> get searchState => getState('search');
  Map<String, dynamic> get jamState => getState('jam'); // 잼 상태 getter 추가
  Map<String, dynamic> get chatState => getState('chat');
  Map<String, dynamic> get settingsState => getState('settings');

  /// 상태 변화 리스너 추가
  void addStateChangeListener(Function(String, dynamic) callback) {
    _stateChangeCallbacks.add(callback);
  }

  /// 상태 변화 리스너 제거
  void removeStateChangeListener(Function(String, dynamic) callback) {
    _stateChangeCallbacks.remove(callback);
  }

  /// 상태 변화 알림
  void _notifyStateChange(String section, dynamic newState) {
    print('🔍 앱 상태 변화 알림 - 섹션: $section');
    for (final callback in _stateChangeCallbacks) {
      callback(section, newState);
    }
  }

  /// 특정 섹션의 상태 업데이트
  Future<void> updateState(String section, Map<String, dynamic> newState) async {
    print('🔍 앱 상태 업데이트 시작 - 섹션: $section');
    
    // 상태 업데이트
    _appState[section] = {..._appState[section], ...newState};
    
    // SharedPreferences에 저장
    await _saveStateToStorage(section, newState);
    
    // 상태 변화 알림
    _notifyStateChange(section, _appState[section]);
    
    print('✅ 앱 상태 업데이트 완료 - 섹션: $section');
  }

  /// 특정 섹션의 상태 가져오기 - GPT 권장: LinkedHashMap 제거
  Map<String, dynamic> getState(String section) {
    // 🔧 GPT 권장: 일반 Map 사용 (LinkedHashMap 제거)
    return Map<String, dynamic>.from(_appState[section]);
  }

  /// 특정 키의 값 업데이트
  Future<void> updateValue(String section, String key, dynamic value) async {
    print('🔍 앱 상태 값 업데이트 - 섹션: $section, 키: $key');
    
    // 상태 업데이트
    _appState[section][key] = value;
    
    // SharedPreferences에 개별 값 저장
    await _saveValueToStorage(section, key, value);
    
    // SharedPreferences에 전체 섹션 상태 저장 (재시작 시 로딩용)
    await _saveStateToStorage(section, _appState[section]);
    
    // 상태 변화 알림
    _notifyStateChange(section, _appState[section]);
    
    print('✅ 앱 상태 값 업데이트 완료 - 섹션: $section, 키: $key');
  }

  /// 앱 시작 시 상태 초기화
  Future<void> initializeAppState() async {
    print('🔍 AppStateManager 초기화 시작');
    
    try {
      // 🔐 AuthStateManager 초기화 완료 대기 (중요!)
      // 로그인 상태가 확정된 후에 사용자별 데이터를 로드해야 함
      print('🔐 인증 상태 확인 중...');
      await Future.delayed(Duration(milliseconds: 100)); // AuthStateManager 완료 대기
      
      final currentUserId = _getCurrentUserId();
      print('🔑 확정된 사용자 ID: $currentUserId');
      
      // SharedPreferences에서 저장된 상태 로드
      await _loadStateFromStorage();
      
      print('✅ AppStateManager 초기화 완료');
      
      // 🔄 모든 UI 동기화를 위한 전역 상태 변화 알림
      print('🔄 초기화 완료 후 UI 전체 동기화 시작');
      for (final section in _appState.keys) {
        _notifyStateChange(section, _appState[section]);
      }
    } catch (e) {
      print('❌ AppStateManager 초기화 실패: $e');
    }
  }

  /// SharedPreferences에 상태 저장 - 저장 성공 여부 확인
  Future<void> _saveStateToStorage(String section, Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      // Map을 JSON 문자열로 변환하여 저장 - 직렬화 가능한 형태로 변환
      final serializableState = _makeSerializable(state);
      final stateJson = jsonEncode(serializableState);
      
      // 🔑 현재 로그인된 사용자 ID 가져오기
      final currentUserId = _getCurrentUserId();
      final userKey = 'app_state_${currentUserId}_$section';
      
      // 🧪 저장 성공 여부 확인
      final success = await prefs.setString(userKey, stateJson);
      if (success) {
        print('✅ 상태 저장 성공 - 섹션: $section, 크기: ${stateJson.length} chars');
        
        // 🔍 저장 직후 즉시 확인 (commit 없이)
        final saved = prefs.getString(userKey);
        if (saved != null && saved == stateJson) {
          print('✅ 저장 검증 성공 - 사용자: $currentUserId, 섹션: $section');
        } else {
          print('❌ 저장 검증 실패 - 사용자: $currentUserId, 섹션: $section, 저장됨: ${saved?.length ?? 0} chars');
        }
      } else {
        print('❌ 상태 저장 실패 - 섹션: $section, setString() returned false');
      }
    } catch (e) {
      print('❌ 상태 저장 실패 - 섹션: $section, 오류: $e');
    }
  }

  /// 현재 로그인된 사용자 ID 가져오기
  String _getCurrentUserId() {
    // AuthStateManager에서 로그인 상태 확인
    final authManager = AuthStateManager.instance;
    if (!authManager.isLoggedIn) {
      return 'guest'; // 로그인 안된 경우 guest 사용
    }
    // 로그인된 경우 이메일을 ID로 사용 (test@example.com → test_example_com)
    return authManager.userName.replaceAll('@', '_').replaceAll('.', '_');
  }

  /// 기존 데이터를 새로운 사용자별 키 시스템으로 마이그레이션
  Future<void> _migrateOldDataIfNeeded(SharedPreferences prefs, String currentUserId) async {
    // 마이그레이션 완료 플래그 확인
    final migrationKey = 'migration_completed_$currentUserId';
    if (prefs.getBool(migrationKey) == true) {
      print('✅ 데이터 마이그레이션 이미 완료됨 - 사용자: $currentUserId');
      return;
    }
    
    print('🔄 기존 데이터 마이그레이션 시작 - 사용자: $currentUserId');
    
    // 이전 키 형태의 데이터를 새로운 키로 이동
    final oldKeys = ['app_state_home', 'app_state_search', 'app_state_jam', 'app_state_chat', 'app_state_settings'];
    int migratedCount = 0;
    
    for (final oldKey in oldKeys) {
      final oldData = prefs.getString(oldKey);
      if (oldData != null) {
        final section = oldKey.replaceFirst('app_state_', '');
        final newKey = 'app_state_${currentUserId}_$section';
        
        // 새로운 키로 데이터 복사
        await prefs.setString(newKey, oldData);
        print('📦 마이그레이션: $oldKey → $newKey');
        migratedCount++;
      }
    }
    
    // AuthStateManager 데이터도 마이그레이션 (프로필 정보)
    if (currentUserId != 'guest') {
      final authKeys = ['userName', 'userNickname', 'userBio', 'userInstruments', 'profileImageName'];
      for (final authKey in authKeys) {
        final authData = prefs.getString(authKey);
        if (authData != null) {
          final newAuthKey = 'auth_${currentUserId}_$authKey';
          await prefs.setString(newAuthKey, authData);
          print('🔐 프로필 마이그레이션: $authKey → $newAuthKey');
          migratedCount++;
        }
      }
    }
    
    // 마이그레이션 완료 플래그 설정
    await prefs.setBool(migrationKey, true);
    print('✅ 데이터 마이그레이션 완료 - $migratedCount개 항목');
  }

  /// SharedPreferences에서 상태 로드 - 사용자별 키 시스템 + 기존 데이터 마이그레이션
  Future<void> _loadStateFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 🔑 현재 로그인된 사용자 ID 가져오기
    final currentUserId = _getCurrentUserId();
    print('🔑 현재 사용자 ID: $currentUserId');
    
    // 🔄 기존 데이터 마이그레이션 (한 번만 실행)
    await _migrateOldDataIfNeeded(prefs, currentUserId);
    
    // 🔍 저장된 모든 키 확인
    final allKeys = prefs.getKeys();
    final userStateKeys = allKeys.where((key) => key.startsWith('app_state_${currentUserId}_')).toList();
    print('🔍 현재 사용자의 저장된 상태 키들: $userStateKeys');
    
    // 각 섹션별로 저장된 상태 로드
    for (final section in _appState.keys) {
      final savedState = prefs.getString('app_state_${currentUserId}_$section');
      
      // 🧪 상세한 저장 상태 확인
      if (savedState == null) {
        print('❌ 저장된 상태 없음 - 섹션: $section (완전히 null)');
        continue;
      } else if (savedState.isEmpty) {
        print('❌ 저장된 상태 없음 - 섹션: $section (빈 문자열)');
        continue;
      } else {
        print('✅ 저장된 상태 발견 - 섹션: $section, 크기: ${savedState.length} chars');
      }
      
      try {
        // JSON 문자열을 Map으로 변환하여 실제 복원
        final Map<String, dynamic> restoredState = jsonDecode(savedState);
        
        // 중첩된 구조도 LinkedHashMap으로 변환
        final convertedState = _convertToLinkedHashMap(restoredState);
        
        // 🔍 기존 상태 백업
        final originalState = Map<String, dynamic>.from(_appState[section]);
        
        // 기존 상태에 복원된 상태 병합 - 타입 안전성을 위해 개별 할당
        convertedState.forEach((key, value) {
          _appState[section]![key] = value;
        });
        
        print('✅ 상태 복원 완료 - 섹션: $section, 항목: ${restoredState.keys.length}개');
        print('📦 복원된 키들: ${restoredState.keys}');
        print('🔄 병합 전 키들: ${originalState.keys}');
        print('🔄 병합 후 키들: ${_appState[section]!.keys}');
        
        // 🔄 UI 강제 업데이트를 위한 상태 변화 알림
        print('🔄 UI 동기화를 위한 상태 변화 알림 - 섹션: $section');
        _notifyStateChange(section, _appState[section]);
      } catch (e) {
        print('❌ 상태 로드 실패 - 섹션: $section, 오류: $e');
        print('📄 원본 데이터: $savedState');
      }
    }
  }

  /// GPT 권장: JSON 직렬화 가능한 형태로 변환 (LinkedHashMap 제거)
  dynamic _makeSerializable(dynamic value) {
    if (value is Map) {
      // 🔧 GPT 권장: LinkedHashMap 대신 일반 Map 사용
      final Map<String, dynamic> safeMap = {};
      value.forEach((key, val) {
        safeMap[key.toString()] = _makeSerializable(val);
      });
      print('🔧 Map 직렬화: ${value.runtimeType} → Map<String, dynamic> (키 ${value.length}개)');
      return safeMap;
    }
    
    if (value is List) {
      // 📋 타입 안전성을 위한 List 변환
      final convertedList = value.map((item) => _makeSerializable(item)).toList();
      print('🔧 List 직렬화: ${value.length}개 요소');
      return convertedList;
    }
    
    // 🖼️ 이미지 데이터 압축 및 크기 제한
    if (value is MemoryImage) {
      try {
        final bytes = value.bytes;
        // 이미지 크기 제한 (100KB)
        if (bytes.length > 100 * 1024) {
          print('⚠️ 이미지 크기 제한: ${(bytes.length / 1024).toStringAsFixed(1)}KB → 100KB로 제한');
          // 여기서 실제 이미지 압축 로직을 구현할 수 있습니다
          return {
            '_type': 'MemoryImage',
            '_data': base64Encode(bytes.take(100 * 1024).toList()),
            '_compressed': true,
          };
        }
        
        return {
          '_type': 'MemoryImage',
          '_data': base64Encode(bytes),
        };
      } catch (e) {
        print('❌ 이미지 직렬화 실패: $e');
        return '👤'; // 기본 아바타로 대체
      }
    }
    
    // 🔢 원시 타입은 그대로 반환
    return value;
  }

  /// GPT 권장: JSON 복원 시 안전한 타입 변환 (LinkedHashMap 제거)
  dynamic _convertToLinkedHashMap(dynamic value) {
    if (value is Map) {
      // 🖼️ 직렬화된 이미지 데이터 복원
      if (value['_type'] == 'MemoryImage' && value['_data'] is String) {
        try {
          final bytes = base64Decode(value['_data'] as String);
          print('🖼️ MemoryImage 복원: Base64 → ${bytes.length} bytes');
          return MemoryImage(bytes);
        } catch (e) {
          print('❌ MemoryImage 복원 실패: $e');
          return '👤'; // 기본 아바타로 대체
        }
      } else if (value['_type'] == 'ImageProvider') {
        return '👤'; // ImageProvider는 기본 아바타로 대체
      }
      
      // 🔧 GPT 권장: LinkedHashMap 대신 일반 Map 사용
      final Map<String, dynamic> safeMap = {};
      value.forEach((key, val) {
        safeMap[key.toString()] = _convertToLinkedHashMap(val);
      });
      print('🔧 Map 복원: ${value.length}개 키 → Map<String, dynamic>');
      return safeMap;
    } 
    
    if (value is List) {
      // 📋 타입 안전성을 위한 List 변환 - 내용에 따라 적절한 타입으로 캐스팅
      final convertedList = value.map((item) => _convertToLinkedHashMap(item)).toList();
      print('🔧 List 복원: ${value.length}개 요소');
      
      // 🔍 리스트 내용을 기반으로 적절한 타입 결정
      if (convertedList.isNotEmpty) {
        final firstItem = convertedList.first;
        if (firstItem is String) {
          // List<String>으로 안전하게 캐스팅
          try {
            return convertedList.cast<String>();
          } catch (e) {
            print('⚠️ List<String> 캐스팅 실패, List<dynamic> 반환');
            return convertedList;
          }
        } else if (firstItem is Map) {
          // List<Map<String, dynamic>>으로 안전하게 캐스팅
          try {
            return convertedList.cast<Map<String, dynamic>>();
          } catch (e) {
            print('⚠️ List<Map> 캐스팅 실패, List<dynamic> 반환');
            return convertedList;
          }
        } else if (firstItem is int) {
          // List<int>로 안전하게 캐스팅
          try {
            return convertedList.cast<int>();
          } catch (e) {
            print('⚠️ List<int> 캐스팅 실패, List<dynamic> 반환');
            return convertedList;
          }
        }
      }
      
      return convertedList;
    }
    
    // 🔢 원시 타입은 그대로 반환
    return value;
  }

  /// SharedPreferences에 값 저장 - 사용자별 키 시스템
  Future<void> _saveValueToStorage(String section, String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 🔑 현재 로그인된 사용자 ID 가져오기
    final currentUserId = _getCurrentUserId();
    
    try {
      if (value is bool) {
        await prefs.setBool('app_state_${currentUserId}_${section}_$key', value);
      } else if (value is int) {
        await prefs.setInt('app_state_${currentUserId}_${section}_$key', value);
      } else if (value is double) {
        await prefs.setDouble('app_state_${currentUserId}_${section}_$key', value);
      } else if (value is String) {
        await prefs.setString('app_state_${currentUserId}_${section}_$key', value);
      } else if (value is List<String>) {
        await prefs.setStringList('app_state_${currentUserId}_${section}_$key', value);
      } else {
        // 복잡한 객체는 JSON으로 저장 - 직렬화 가능한 형태로 변환
        final serializableValue = _makeSerializable(value);
        final jsonValue = jsonEncode(serializableValue);
        
        // 저장소 용량 체크
        if (jsonValue.length > 500000) { // 500KB 제한
          print('⚠️ 저장소 용량 초과 감지: ${(jsonValue.length / 1024).toStringAsFixed(1)}KB');
          await _cleanupOldData(prefs, currentUserId, section);
        }
        
        await prefs.setString('app_state_${currentUserId}_${section}_$key', jsonValue);
      }
      
      print('💾 개별 값 저장 완료 - 사용자: $currentUserId, ${section}.$key');
    } catch (e) {
      if (e.toString().contains('QuotaExceededError')) {
        print('❌ 저장소 용량 초과: 데이터 정리 시작');
        await _cleanupOldData(prefs, currentUserId, section);
        // 재시도
        try {
          final serializableValue = _makeSerializable(value);
          final jsonValue = jsonEncode(serializableValue);
          await prefs.setString('app_state_${currentUserId}_${section}_$key', jsonValue);
          print('✅ 데이터 정리 후 저장 성공');
        } catch (retryError) {
          print('❌ 재시도 실패: $retryError');
        }
      } else {
        print('❌ 개별 값 저장 실패 - ${section}.$key: $e');
      }
    }
  }

  /// 오래된 데이터 정리
  Future<void> _cleanupOldData(SharedPreferences prefs, String userId, String section) async {
    try {
      final keys = prefs.getKeys();
      final targetKeys = keys.where((key) => 
        key.startsWith('app_state_${userId}_${section}_') && 
        key != 'app_state_${userId}_${section}_feedData' // 피드 데이터는 보존
      ).toList();
      
      if (targetKeys.isNotEmpty) {
        // 가장 오래된 데이터부터 삭제
        for (final key in targetKeys.take(targetKeys.length ~/ 2)) {
          await prefs.remove(key);
          print('🗑️ 오래된 데이터 삭제: $key');
        }
      }
    } catch (e) {
      print('❌ 데이터 정리 실패: $e');
    }
  }

  /// 현재 상태 정보 출력 (디버깅용)
  void printCurrentState() {
    print('🔍 현재 앱 상태:');
    for (final entry in _appState.entries) {
      print('  - ${entry.key}: ${entry.value}');
    }
  }
} 