import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  // 캐시 키 상수
  static const String _feedsCacheKey = 'cached_feeds';
  static const String _userDataCacheKey = 'cached_user_data';
  static const String _searchHistoryCacheKey = 'cached_search_history';
  static const String _favoritesCacheKey = 'cached_favorites';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _pendingActionsKey = 'pending_actions';

  // 캐시 만료 시간 (24시간)
  static const Duration _cacheExpiration = Duration(hours: 24);

  /// 네트워크 상태 확인 (시뮬레이션)
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// 네트워크 상태 토글 (테스트용)
  void toggleNetworkStatus() {
    _isOnline = !_isOnline;
    print('네트워크 상태: ${_isOnline ? "온라인" : "오프라인"}');
  }

  /// 피드 데이터 캐시
  Future<void> cacheFeeds(List<Map<String, dynamic>> feeds) async {
    if (!_isOnline) return; // 오프라인일 때는 캐시하지 않음

    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'feeds': feeds,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    await prefs.setString(_feedsCacheKey, jsonEncode(cacheData));
    await _updateLastSyncTime();
  }

  /// 캐시된 피드 데이터 로드
  Future<List<Map<String, dynamic>>> loadCachedFeeds() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_feedsCacheKey);
    
    if (cachedData == null) return [];
    
    try {
      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = data['timestamp'] as int;
      final feeds = data['feeds'] as List;
      
      // 캐시 만료 확인
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      
      if (now.difference(cacheTime) > _cacheExpiration) {
        // 캐시가 만료되었으면 삭제
        await prefs.remove(_feedsCacheKey);
        return [];
      }
      
      return feeds.cast<Map<String, dynamic>>();
    } catch (e) {
      print('캐시된 피드 로드 오류: $e');
      return [];
    }
  }

  /// 사용자 데이터 캐시
  Future<void> cacheUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataCacheKey, jsonEncode(userData));
  }

  /// 캐시된 사용자 데이터 로드
  Future<Map<String, dynamic>?> loadCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_userDataCacheKey);
    
    if (cachedData == null) return null;
    
    try {
      return jsonDecode(cachedData) as Map<String, dynamic>;
    } catch (e) {
      print('캐시된 사용자 데이터 로드 오류: $e');
      return null;
    }
  }

  /// 검색 기록 캐시
  Future<void> cacheSearchHistory(List<String> searchHistory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_searchHistoryCacheKey, searchHistory);
  }

  /// 캐시된 검색 기록 로드
  Future<List<String>> loadCachedSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_searchHistoryCacheKey) ?? [];
  }

  /// 즐겨찾기 캐시
  Future<void> cacheFavorites(List<Map<String, dynamic>> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = favorites.map((f) => jsonEncode(f)).toList();
    await prefs.setStringList(_favoritesCacheKey, favoritesJson);
  }

  /// 캐시된 즐겨찾기 로드
  Future<List<Map<String, dynamic>>> loadCachedFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesCacheKey) ?? [];
    
    return favoritesJson.map((json) {
      try {
        return jsonDecode(json) as Map<String, dynamic>;
      } catch (e) {
        return <String, dynamic>{};
      }
    }).where((favorite) => favorite.isNotEmpty).toList();
  }

  /// 마지막 동기화 시간 업데이트
  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// 마지막 동기화 시간 확인
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncTimeKey);
    
    if (timestamp == null) return null;
    
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// 대기 중인 액션 저장 (오프라인 시)
  Future<void> savePendingAction(String action, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingActions = prefs.getStringList(_pendingActionsKey) ?? [];
    
    final actionData = {
      'action': action,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    pendingActions.add(jsonEncode(actionData));
    await prefs.setStringList(_pendingActionsKey, pendingActions);
  }

  /// 대기 중인 액션 로드
  Future<List<Map<String, dynamic>>> loadPendingActions() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingActions = prefs.getStringList(_pendingActionsKey) ?? [];
    
    return pendingActions.map((json) {
      try {
        return jsonDecode(json) as Map<String, dynamic>;
      } catch (e) {
        return <String, dynamic>{};
      }
    }).where((action) => action.isNotEmpty).toList();
  }

  /// 대기 중인 액션 처리 (온라인 복귀 시)
  Future<void> processPendingActions() async {
    if (!_isOnline) return;
    
    final pendingActions = await loadPendingActions();
    if (pendingActions.isEmpty) return;
    
    print('대기 중인 액션 처리 중: ${pendingActions.length}개');
    
    // 실제로는 서버에 동기화하는 로직
    for (final action in pendingActions) {
      print('처리 중: ${action['action']}');
      await Future.delayed(const Duration(milliseconds: 100)); // 시뮬레이션
    }
    
    // 처리 완료 후 대기 중인 액션 삭제
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingActionsKey);
  }

  /// 오프라인 모드에서 액션 처리
  Future<void> handleOfflineAction(String action, Map<String, dynamic> data) async {
    if (_isOnline) {
      // 온라인일 때는 즉시 처리
      await _processAction(action, data);
    } else {
      // 오프라인일 때는 대기 중인 액션으로 저장
      await savePendingAction(action, data);
      
      // 로컬 상태 업데이트
      await _updateLocalState(action, data);
    }
  }

  /// 액션 처리 (온라인)
  Future<void> _processAction(String action, Map<String, dynamic> data) async {
    // 실제로는 서버 API 호출
    print('온라인 액션 처리: $action');
    await Future.delayed(const Duration(milliseconds: 200)); // 시뮬레이션
  }

  /// 로컬 상태 업데이트
  Future<void> _updateLocalState(String action, Map<String, dynamic> data) async {
    switch (action) {
      case 'like':
        // 로컬 좋아요 상태 업데이트
        break;
      case 'save':
        // 로컬 저장 상태 업데이트
        break;
      case 'follow':
        // 로컬 팔로우 상태 업데이트
        break;
      case 'comment':
        // 로컬 댓글 상태 업데이트
        break;
    }
  }

  /// 캐시 정리
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_feedsCacheKey);
    await prefs.remove(_userDataCacheKey);
    await prefs.remove(_searchHistoryCacheKey);
    await prefs.remove(_favoritesCacheKey);
    await prefs.remove(_lastSyncTimeKey);
    await prefs.remove(_pendingActionsKey);
  }

  /// 캐시 상태 확인
  Future<Map<String, dynamic>> getCacheStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncTime = await getLastSyncTime();
    final pendingActions = await loadPendingActions();
    
    return {
      'isOnline': _isOnline,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'pendingActionsCount': pendingActions.length,
      'hasCachedFeeds': prefs.getString(_feedsCacheKey) != null,
      'hasCachedUserData': prefs.getString(_userDataCacheKey) != null,
    };
  }

  /// 오프라인 모드 활성화/비활성화
  void setOfflineMode(bool enabled) {
    _isOnline = !enabled;
    print('오프라인 모드: ${enabled ? "활성화" : "비활성화"}');
  }

  /// 네트워크 연결 상태 모니터링 (시뮬레이션)
  Stream<bool> get networkStatusStream {
    return Stream.periodic(const Duration(seconds: 10), (_) {
      // 실제로는 네트워크 상태 확인
      return _isOnline;
    });
  }

  /// 동기화 상태 확인
  Future<bool> needsSync() async {
    final lastSyncTime = await getLastSyncTime();
    if (lastSyncTime == null) return true;
    
    final timeSinceLastSync = DateTime.now().difference(lastSyncTime);
    return timeSinceLastSync > const Duration(minutes: 30);
  }

  /// 강제 동기화
  Future<void> forceSync() async {
    if (!_isOnline) {
      print('오프라인 상태에서는 동기화할 수 없습니다.');
      return;
    }
    
    print('강제 동기화 시작...');
    
    // 대기 중인 액션 처리
    await processPendingActions();
    
    // 캐시 업데이트
    await _updateLastSyncTime();
    
    print('동기화 완료');
  }
} 