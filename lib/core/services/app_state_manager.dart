import 'dart:convert';
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
      'likedFeeds': <int, bool>{}, // 🔧 리터럴 대신 생성자 사용
      'savedFeeds': <int, bool>{}, // 🔧 리터럴 대신 생성자 사용
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
      'commentData': <String, List<Map<String, dynamic>>>{}, // 🔧 리터럴 대신 생성자 사용
      'replyData': <String, List<Map<String, dynamic>>>{}, // 🔧 리터럴 대신 생성자 사용
      'nestedReplyData': <String, List<Map<String, dynamic>>>{}, // 🔧 리터럴 대신 생성자 사용
      'commentCounts': <int, int>{}, // 🔧 리터럴 대신 생성자 사용
      'likeCounts': <int, int>{}, // 🔧 리터럴 대신 생성자 사용
    },
    
    // 사용자 액션 상태 - 수정: List는 리터럴 사용
    'userActions': {
      'likedPosts': <int, bool>{}, // 🔧 리터럴 대신 생성자 사용
      'savedPosts': <int, bool>{}, // 🔧 리터럴 대신 생성자 사용
      'followedUsers': <String>[], // 🔧 List 리터럴은 안전함
      'userProfileImage': <String, dynamic>{}, // 🔧 리터럴 대신 생성자 사용
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
      'lastReadMessages': <int, String>{}, // 🔧 리터럴 대신 생성자 사용
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
    for (final callback in _stateChangeCallbacks) {
      callback(section, newState);
    }
  }

  /// 특정 섹션의 상태 업데이트
  Future<void> updateState(String section, Map<String, dynamic> newState) async {
    
    // 상태 업데이트
    _appState[section] = {..._appState[section], ...newState};
    
    // SharedPreferences에 저장
    await _saveStateToStorage(section, newState);
    
    // 상태 변화 알림
    _notifyStateChange(section, _appState[section]);
    
  }

  /// 특정 섹션의 상태 가져오기 - GPT 권장: LinkedHashMap 제거
  Map<String, dynamic> getState(String section) {
    // 🔧 GPT 권장: 일반 Map 사용 (LinkedHashMap 제거)
    return Map<String, dynamic>.from(_appState[section]);
  }

  /// 특정 키의 값 업데이트
  Future<void> updateValue(String section, String key, dynamic value) async {
    
    // 상태 업데이트
    _appState[section][key] = value;
    
    // SharedPreferences에 개별 값 저장
    await _saveValueToStorage(section, key, value);
    
    // SharedPreferences에 전체 섹션 상태 저장 (재시작 시 로딩용)
    await _saveStateToStorage(section, _appState[section]);
    
    // 상태 변화 알림
    _notifyStateChange(section, _appState[section]);
    
  }

  /// 앱 시작 시 상태 초기화
  Future<void> initializeAppState() async {
    
    try {
      // 🔐 AuthStateManager 초기화 완료 대기 (중요!)
      // 로그인 상태가 확정된 후에 사용자별 데이터를 로드해야 함
      await Future.delayed(Duration(milliseconds: 100)); // AuthStateManager 완료 대기

      // SharedPreferences에서 저장된 상태 로드
      await _loadStateFromStorage();
      
      
      // 🔄 모든 UI 동기화를 위한 전역 상태 변화 알림
      for (final section in _appState.keys) {
        _notifyStateChange(section, _appState[section]);
      }
    } catch (e) { // ignore: empty_catches
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
        
        // 🔍 저장 직후 즉시 확인 (commit 없이)
        final saved = prefs.getString(userKey);
        if (saved != null && saved == stateJson) {
        } else {
        }
      } else {
      }
    } catch (e) { // ignore: empty_catches
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
      return;
    }
    
    
    // 이전 키 형태의 데이터를 새로운 키로 이동
    final oldKeys = ['app_state_home', 'app_state_search', 'app_state_jam', 'app_state_chat', 'app_state_settings'];
    for (final oldKey in oldKeys) {
      final oldData = prefs.getString(oldKey);
      if (oldData != null) {
        final section = oldKey.replaceFirst('app_state_', '');
        final newKey = 'app_state_${currentUserId}_$section';

        // 새로운 키로 데이터 복사
        await prefs.setString(newKey, oldData);
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
        }
      }
    }
    
    // 마이그레이션 완료 플래그 설정
    await prefs.setBool(migrationKey, true);
  }

  /// SharedPreferences에서 상태 로드 - 사용자별 키 시스템 + 기존 데이터 마이그레이션
  Future<void> _loadStateFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 🔑 현재 로그인된 사용자 ID 가져오기
    final currentUserId = _getCurrentUserId();
    
    // 🔄 기존 데이터 마이그레이션 (한 번만 실행)
    await _migrateOldDataIfNeeded(prefs, currentUserId);
    
    // 각 섹션별로 저장된 상태 로드
    for (final section in _appState.keys) {
      final savedState = prefs.getString('app_state_${currentUserId}_$section');
      
      // 🧪 상세한 저장 상태 확인
      if (savedState == null) {
        continue;
      } else if (savedState.isEmpty) {
        continue;
      } else {
      }
      
      try {
        // JSON 문자열을 Map으로 변환하여 실제 복원
        final Map<String, dynamic> restoredState = jsonDecode(savedState);
        
        // 중첩된 구조도 LinkedHashMap으로 변환
        final convertedState = _convertToLinkedHashMap(restoredState);
        
        // 기존 상태에 복원된 상태 병합 - 타입 안전성을 위해 개별 할당
        convertedState.forEach((key, value) {
          _appState[section]![key] = value;
        });
        
        
        // 🔄 UI 강제 업데이트를 위한 상태 변화 알림
        _notifyStateChange(section, _appState[section]);
      } catch (e) { // ignore: empty_catches
      }
    }
  }

  /// GPT 권장: 완전한 JSON 직렬화 호환 변환 함수
  dynamic _makeSerializable(dynamic value) {
    // 🗝️ 핵심: 모든 Map은 key를 String으로 변환 (GPT 권장 방식)
    if (value is Map) {
      final Map<String, dynamic> serializable = {};
      value.forEach((key, val) {
        // 🔧 int key → String key 변환 (JSON 호환)
        serializable[key.toString()] = _makeSerializable(val);
      });
      return serializable;
    }
    
    // 📋 Set → List 변환 (JSON은 Set을 지원하지 않음)
    if (value is Set) {
      final list = value.map(_makeSerializable).toList();
      return list;
    }
    
    // 📋 List 재귀 처리
    if (value is List) {
      return value.map((item) => _makeSerializable(item)).toList();
    }
    
    // 🖼️ MemoryImage → Base64 변환
    if (value is MemoryImage) {
      return {
        '_type': 'MemoryImage',
        '_data': base64Encode(value.bytes),
      };
    }
    
    // 🖼️ ImageProvider → 문자열 변환
    if (value is ImageProvider) {
      return {
        '_type': 'ImageProvider',
        '_data': '👤', // 기본 아바타 문자열
      };
    }
    
    // 🛡️ 알 수 없는 객체 타입 안전 처리
    if (value != null && value is! String && value is! int && value is! bool && value is! double) {
      return value.toString();
    }
    
    // 🔢 원시 타입 (String, int, bool, double, null)
    return value;
  }

  /// GPT 권장: JSON 복원 시 안전한 타입 변환 (LinkedHashMap 제거)
  dynamic _convertToLinkedHashMap(dynamic value) {
    if (value is Map) {
      // 🖼️ 직렬화된 이미지 데이터 복원
      if (value['_type'] == 'MemoryImage' && value['_data'] is String) {
        try {
          final bytes = base64Decode(value['_data'] as String);
          return MemoryImage(bytes);
        } catch (e) {
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
      return safeMap;
    } 
    
    if (value is List) {
      // 📋 타입 안전성을 위한 List 변환 - 내용에 따라 적절한 타입으로 캐스팅
      final convertedList = value.map((item) => _convertToLinkedHashMap(item)).toList();
      
      // 🔍 리스트 내용을 기반으로 적절한 타입 결정
      if (convertedList.isNotEmpty) {
        final firstItem = convertedList.first;
        if (firstItem is String) {
          // List<String>으로 안전하게 캐스팅
          try {
            return convertedList.cast<String>();
          } catch (e) {
            return convertedList;
          }
        } else if (firstItem is Map) {
          // List<Map<String, dynamic>>으로 안전하게 캐스팅
          try {
            return convertedList.cast<Map<String, dynamic>>();
          } catch (e) {
            return convertedList;
          }
        } else if (firstItem is int) {
          // List<int>로 안전하게 캐스팅
          try {
            return convertedList.cast<int>();
          } catch (e) {
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
        await prefs.setString('app_state_${currentUserId}_${section}_$key', jsonValue);
      }
      
    } catch (e) { // ignore: empty_catches
    }
  }

} 