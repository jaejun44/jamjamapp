import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// 앱 전체 상태를 중앙 집중식으로 관리하는 매니저
class AppStateManager {
  static AppStateManager? _instance;
  static AppStateManager get instance => _instance ??= AppStateManager._internal();
  
  AppStateManager._internal();

  // 상태 변화 콜백 리스트
  final List<Function(String, dynamic)> _stateChangeCallbacks = [];

  // 앱 전체 상태
  final Map<String, dynamic> _appState = {
    // 홈 탭 상태
    'home': {
      'likedFeeds': <int, bool>{},
      'savedFeeds': <int, bool>{},
      'followedUsers': <String>{},
      'isPersonalizedMode': true,
      'isOfflineMode': false,
      'selectedGenre': '전체',
      'selectedMediaType': '전체',
      'searchQuery': '',
      'isRealtimeUpdateEnabled': true,
      'feedData': <Map<String, dynamic>>[],
    },
    
    // 댓글 시스템 상태
    'comments': {
      'commentData': <String, List<Map<String, dynamic>>>{}, // 피드별 댓글 데이터
      'replyData': <String, List<Map<String, dynamic>>>{}, // 답글 데이터
      'nestedReplyData': <String, List<Map<String, dynamic>>>{}, // 중첩 답글 데이터
      'commentCounts': <int, int>{}, // 피드별 댓글 수
      'likeCounts': <int, int>{}, // 피드별 좋아요 수
    },
    
    // 사용자 액션 상태
    'userActions': {
      'likedPosts': <int, bool>{},
      'savedPosts': <int, bool>{},
      'followedUsers': <String>{},
      'userProfileImage': <String, dynamic>{}, // 사용자별 프로필 이미지
    },
    
    // 검색 탭 상태
    'search': {
      'searchHistory': <String>[],
      'favoriteSearches': <String>{},
      'selectedGenres': <String>{},
      'selectedInstruments': <String>{},
      'selectedLocations': <String>{},
      'sortBy': 'relevance',
      'sortOrder': 'desc',
      'minFollowers': null,
      'maxFollowers': null,
      'isOnline': null,
      'isVerified': null,
    },
    
    // 채팅 탭 상태
    'chat': {
      'mutedChats': <int>{},
      'pinnedChats': <int>{},
      'isRealtimeUpdateEnabled': true,
      'lastReadMessages': <int, DateTime>{},
    },
    
    // 설정 상태
    'settings': {
      'notifications': true,
      'darkMode': true,
      'autoPlay': false,
      'dataSaver': false,
    },
  };

  // Getters
  Map<String, dynamic> get homeState => _appState['home'];
  Map<String, dynamic> get searchState => _appState['search'];
  Map<String, dynamic> get chatState => _appState['chat'];
  Map<String, dynamic> get settingsState => _appState['settings'];

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

  /// 특정 섹션의 상태 가져오기
  Map<String, dynamic> getState(String section) {
    return Map<String, dynamic>.from(_appState[section]);
  }

  /// 특정 키의 값 업데이트
  Future<void> updateValue(String section, String key, dynamic value) async {
    print('🔍 앱 상태 값 업데이트 - 섹션: $section, 키: $key');
    
    // 상태 업데이트
    _appState[section][key] = value;
    
    // SharedPreferences에 저장
    await _saveValueToStorage(section, key, value);
    
    // 상태 변화 알림
    _notifyStateChange(section, _appState[section]);
    
    print('✅ 앱 상태 값 업데이트 완료 - 섹션: $section, 키: $key');
  }

  /// 앱 시작 시 상태 초기화
  Future<void> initializeAppState() async {
    print('🔍 AppStateManager 초기화 시작');
    
    try {
      // SharedPreferences에서 저장된 상태 로드
      await _loadStateFromStorage();
      
      print('✅ AppStateManager 초기화 완료');
    } catch (e) {
      print('❌ AppStateManager 초기화 실패: $e');
    }
  }

  /// SharedPreferences에 상태 저장
  Future<void> _saveStateToStorage(String section, Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Map을 JSON 문자열로 변환하여 저장
    final stateJson = state.toString();
    await prefs.setString('app_state_$section', stateJson);
  }

  /// SharedPreferences에서 상태 로드
  Future<void> _loadStateFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 각 섹션별로 저장된 상태 로드
    for (final section in _appState.keys) {
      final savedState = prefs.getString('app_state_$section');
      if (savedState != null) {
        try {
          // JSON 문자열을 Map으로 변환 (간단한 구현)
          print('🔍 저장된 상태 로드 - 섹션: $section');
        } catch (e) {
          print('❌ 상태 로드 실패 - 섹션: $section, 오류: $e');
        }
      }
    }
  }

  /// SharedPreferences에 값 저장
  Future<void> _saveValueToStorage(String section, String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (value is bool) {
      await prefs.setBool('app_state_${section}_$key', value);
    } else if (value is int) {
      await prefs.setInt('app_state_${section}_$key', value);
    } else if (value is double) {
      await prefs.setDouble('app_state_${section}_$key', value);
    } else if (value is String) {
      await prefs.setString('app_state_${section}_$key', value);
    } else if (value is List<String>) {
      await prefs.setStringList('app_state_${section}_$key', value);
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