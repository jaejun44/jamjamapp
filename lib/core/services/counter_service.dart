import 'dart:convert';
import 'dart:collection';
import 'package:shared_preferences/shared_preferences.dart';

/// 좋아요, 댓글, 공유 등 모든 카운트를 중앙에서 관리하는 서비스
class CounterService {
  static final CounterService _instance = CounterService._internal();
  factory CounterService() => _instance;
  CounterService._internal();
  
  static CounterService get instance => _instance;

  // 메모리 캐시 - ChatGPT-4o 권장: 명시적 생성자 사용
  Map<String, Map<int, int>> _counters = {
    'likes': Map<int, int>(),      // 🔧 리터럴 대신 생성자 사용
    'comments': Map<int, int>(),   // 🔧 리터럴 대신 생성자 사용
    'shares': Map<int, int>(),     // 🔧 리터럴 대신 생성자 사용
    'jamLikes': Map<int, int>(),   // 🔧 리터럴 대신 생성자 사용
  };
  
  // 사용자별 좋아요 상태 (userId -> feedId -> bool) - ChatGPT-4o 권장
  Map<String, Map<int, bool>> _userLikes = Map<String, Map<int, bool>>();
  
  // 변화 알림 콜백
  List<Function(String type, int id, int newCount)> _listeners = [];

  /// 서비스 초기화
  Future<void> initialize() async {
    try {
      print('🔢 CounterService 초기화 시작...');
      await _loadCountersFromStorage();
      await _loadUserLikesFromStorage();
      print('✅ CounterService 초기화 완료');
    } catch (e) {
      print('❌ CounterService 초기화 실패: $e');
    }
  }

  /// SharedPreferences에서 카운터 데이터 로드
  Future<void> _loadCountersFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    for (final type in _counters.keys) {
      final data = prefs.getString('counters_$type');
      if (data != null) {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        _counters[type] = decoded.map((k, v) => MapEntry(int.parse(k), v as int));
        print('📊 $type 카운터 로드: ${_counters[type]!.length}개');
      }
    }
  }

  /// SharedPreferences에서 사용자 좋아요 상태 로드  
  Future<void> _loadUserLikesFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_likes');
    if (data != null) {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      // ChatGPT-4o 권장: 명시적 생성자 사용
      _userLikes = Map<String, Map<int, bool>>(); // 🔧 리터럴 대신 생성자 사용
      for (final entry in decoded.entries) {
        _userLikes[entry.key] = Map<int, bool>(); // 🔧 리터럴 대신 생성자 사용
        final userLikes = entry.value as Map<String, dynamic>;
        for (final e in userLikes.entries) {
          _userLikes[entry.key]![int.parse(e.key)] = e.value as bool;
        }
      }
      print('👤 사용자 좋아요 상태 로드: ${_userLikes.length}명');
    }
  }

  /// 카운터 데이터를 SharedPreferences에 저장
  Future<void> _saveCountersToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    for (final type in _counters.keys) {
      final data = _counters[type]!.map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString('counters_$type', jsonEncode(data));
    }
  }

  /// 사용자 좋아요 상태를 SharedPreferences에 저장
  Future<void> _saveUserLikesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _userLikes.map((userId, userLikeData) => MapEntry(
      userId,
      userLikeData.map((k, v) => MapEntry(k.toString(), v))
    ));
    await prefs.setString('user_likes', jsonEncode(data));
  }

  /// 카운트 가져오기
  int getCount(String type, int id) {
    return _counters[type]?[id] ?? 0;
  }

  /// 사용자의 좋아요 상태 가져오기
  bool getUserLikeStatus(String userId, int feedId) {
    return _userLikes[userId]?[feedId] ?? false;
  }

  /// 좋아요 토글 (실제 카운트와 사용자 상태 모두 업데이트)
  Future<bool> toggleLike(String userId, int feedId) async {
    try {
      // 현재 상태 확인
      final currentUserLiked = getUserLikeStatus(userId, feedId);
      final newUserLiked = !currentUserLiked;
      
      // 사용자 좋아요 상태 업데이트 - ChatGPT-4o 권장
      _userLikes[userId] ??= Map<int, bool>(); // 🔧 리터럴 대신 생성자 사용
      _userLikes[userId]![feedId] = newUserLiked;
      
      // 전체 좋아요 카운트 업데이트
      final currentCount = getCount('likes', feedId);
      final newCount = newUserLiked ? currentCount + 1 : currentCount - 1;
      _counters['likes']![feedId] = newCount.clamp(0, double.infinity).toInt();
      
      // 저장
      await _saveCountersToStorage();
      await _saveUserLikesToStorage();
      
      // 리스너들에게 알림
      _notifyListeners('likes', feedId, _counters['likes']![feedId]!);
      
      print('👍 좋아요 토글: feedId=$feedId, userId=$userId, liked=$newUserLiked, count=$newCount');
      return newUserLiked;
    } catch (e) {
      print('❌ 좋아요 토글 실패: $e');
      return getUserLikeStatus(userId, feedId);
    }
  }

  /// 댓글 카운트 업데이트 (CommentService와 연동)
  Future<void> updateCommentCount(int feedId, int newCount) async {
    try {
      _counters['comments']![feedId] = newCount;
      await _saveCountersToStorage();
      _notifyListeners('comments', feedId, newCount);
      print('💬 댓글 카운트 업데이트: feedId=$feedId, count=$newCount');
    } catch (e) {
      print('❌ 댓글 카운트 업데이트 실패: $e');
    }
  }

  /// 공유 카운트 증가
  Future<void> incrementShareCount(int feedId) async {
    try {
      final currentCount = getCount('shares', feedId);
      final newCount = currentCount + 1;
      _counters['shares']![feedId] = newCount;
      await _saveCountersToStorage();
      _notifyListeners('shares', feedId, newCount);
      print('🔗 공유 카운트 증가: feedId=$feedId, count=$newCount');
    } catch (e) {
      print('❌ 공유 카운트 증가 실패: $e');
    }
  }

  /// 초기 카운트 설정 (피드 생성 시)
  Future<void> initializeFeedCounts(int feedId, {int likes = 0, int comments = 0, int shares = 0}) async {
    try {
      _counters['likes']![feedId] = likes;
      _counters['comments']![feedId] = comments;
      _counters['shares']![feedId] = shares;
      await _saveCountersToStorage();
      print('🆕 피드 카운트 초기화: feedId=$feedId, likes=$likes, comments=$comments, shares=$shares');
    } catch (e) {
      print('❌ 피드 카운트 초기화 실패: $e');
    }
  }

  /// 변화 알림 리스너 추가
  void addListener(Function(String type, int id, int newCount) listener) {
    _listeners.add(listener);
  }

  /// 변화 알림 리스너 제거
  void removeListener(Function(String type, int id, int newCount) listener) {
    _listeners.remove(listener);
  }

  /// 리스너들에게 변화 알림
  void _notifyListeners(String type, int id, int newCount) {
    for (final listener in _listeners) {
      try {
        listener(type, id, newCount);
      } catch (e) {
        print('❌ 리스너 알림 실패: $e');
      }
    }
  }

  /// 모든 카운트 데이터 초기화 (개발/테스트용)
  Future<void> clearAllCounts() async {
    try {
      // ChatGPT-4o 권장: 명시적 생성자 사용
      _counters = {
        'likes': Map<int, int>(), // 🔧 리터럴 대신 생성자 사용
        'comments': Map<int, int>(), // 🔧 리터럴 대신 생성자 사용
        'shares': Map<int, int>(), // 🔧 리터럴 대신 생성자 사용
        'jamLikes': Map<int, int>(), // 🔧 리터럴 대신 생성자 사용
      };
      _userLikes = Map<String, Map<int, bool>>(); // 🔧 리터럴 대신 생성자 사용
      
      final prefs = await SharedPreferences.getInstance();
      for (final type in ['likes', 'comments', 'shares', 'jamLikes']) {
        await prefs.remove('counters_$type');
      }
      await prefs.remove('user_likes');
      
      print('🗑️ 모든 카운트 데이터 초기화 완료');
    } catch (e) {
      print('❌ 카운트 데이터 초기화 실패: $e');
    }
  }

  /// 디버그: 현재 상태 출력
  void printDebugInfo() {
    print('🔢 === CounterService 디버그 정보 ===');
    print('카운터: $_counters');
    print('사용자 좋아요: $_userLikes');
    print('리스너 수: ${_listeners.length}');
  }
}