import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class RecommendationService {
  static final RecommendationService _instance = RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  // 사용자 선호도 데이터
  Map<String, double> _userPreferences = {};
  List<String> _userInterests = [];
  List<String> _userGenres = [];
  List<String> _userInstruments = [];
  
  // 추천 알고리즘 가중치
  static const double _genreWeight = 0.4;
  static const double _interestWeight = 0.3;
  static const double _instrumentWeight = 0.2;
  static const double _popularityWeight = 0.1;

  /// 사용자 선호도 초기화
  Future<void> initializeUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 저장된 선호도 로드
    _userGenres = prefs.getStringList('user_genres') ?? ['팝', '재즈'];
    _userInstruments = prefs.getStringList('user_instruments') ?? ['기타', '피아노'];
    _userInterests = prefs.getStringList('user_interests') ?? ['음악', '연주'];
    
    // 선호도 점수 계산
    _calculatePreferences();
  }

  /// 선호도 점수 계산
  void _calculatePreferences() {
    _userPreferences.clear();
    
    // 장르별 선호도
    for (String genre in _userGenres) {
      _userPreferences[genre] = (_userPreferences[genre] ?? 0) + _genreWeight;
    }
    
    // 관심사별 선호도
    for (String interest in _userInterests) {
      _userPreferences[interest] = (_userPreferences[interest] ?? 0) + _interestWeight;
    }
    
    // 악기별 선호도
    for (String instrument in _userInstruments) {
      _userPreferences[instrument] = (_userPreferences[instrument] ?? 0) + _instrumentWeight;
    }
  }

  /// 사용자 행동 기록 (좋아요, 저장, 팔로우 등)
  Future<void> recordUserAction(String action, Map<String, dynamic> feed) async {
    final prefs = await SharedPreferences.getInstance();
    
    switch (action) {
      case 'like':
        _updatePreferenceForFeed(feed, 0.1);
        break;
      case 'save':
        _updatePreferenceForFeed(feed, 0.2);
        break;
      case 'follow':
        _updatePreferenceForFeed(feed, 0.3);
        break;
      case 'share':
        _updatePreferenceForFeed(feed, 0.15);
        break;
      case 'comment':
        _updatePreferenceForFeed(feed, 0.25);
        break;
    }
    
    // 선호도 저장
    await _savePreferences();
  }

  /// 피드 기반 선호도 업데이트
  void _updatePreferenceForFeed(Map<String, dynamic> feed, double weight) {
    // 장르 선호도 업데이트
    if (feed['genre'] != null) {
      _userPreferences[feed['genre']] = (_userPreferences[feed['genre']] ?? 0) + weight;
    }
    
    // 태그 기반 선호도 업데이트
    if (feed['tags'] != null) {
      for (String tag in feed['tags']) {
        _userPreferences[tag] = (_userPreferences[tag] ?? 0) + weight * 0.5;
      }
    }
    
    // 악기 선호도 업데이트 (태그에서 악기 추출)
    if (feed['tags'] != null) {
      for (String tag in feed['tags']) {
        if (_isInstrument(tag)) {
          _userPreferences[tag] = (_userPreferences[tag] ?? 0) + weight * 0.3;
        }
      }
    }
  }

  /// 악기 여부 확인
  bool _isInstrument(String tag) {
    final instruments = [
      '기타', '피아노', '드럼', '베이스', '바이올린', '첼로', '색소폰',
      '트럼펫', '플루트', '클라리넷', '하모니카', '우쿨렐레', '만돌린'
    ];
    return instruments.contains(tag);
  }

  /// 선호도 저장
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 선호도가 높은 항목들을 저장
    final sortedPreferences = _userPreferences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topGenres = <String>[];
    final topInstruments = <String>[];
    final topInterests = <String>[];
    
    for (var entry in sortedPreferences.take(10)) {
      if (_isInstrument(entry.key)) {
        topInstruments.add(entry.key);
      } else if (_isGenre(entry.key)) {
        topGenres.add(entry.key);
      } else {
        topInterests.add(entry.key);
      }
    }
    
    await prefs.setStringList('user_genres', topGenres);
    await prefs.setStringList('user_instruments', topInstruments);
    await prefs.setStringList('user_interests', topInterests);
  }

  /// 장르 여부 확인
  bool _isGenre(String tag) {
    final genres = [
      '팝', '재즈', '락', '클래식', '일렉트로닉', '힙합', 'R&B', '컨트리',
      '블루스', '펑크', '메탈', '포크', '소울', '레게', '디스코'
    ];
    return genres.contains(tag);
  }

  /// 개인화된 피드 추천
  List<Map<String, dynamic>> getPersonalizedFeeds(List<Map<String, dynamic>> allFeeds) {
    if (_userPreferences.isEmpty) {
      return allFeeds; // 선호도가 없으면 전체 피드 반환
    }

    // 각 피드에 점수 계산
    final scoredFeeds = allFeeds.map((feed) {
      double score = _calculateFeedScore(feed);
      return {
        'feed': feed,
        'score': score,
      };
    }).toList();

    // 점수순으로 정렬
    scoredFeeds.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    // 상위 70%는 개인화, 하위 30%는 다양성을 위해 랜덤 선택
    final personalizedCount = (scoredFeeds.length * 0.7).round();
    final personalized = scoredFeeds.take(personalizedCount).map((item) => item['feed'] as Map<String, dynamic>).toList();
    
    final remaining = scoredFeeds.skip(personalizedCount).map((item) => item['feed'] as Map<String, dynamic>).toList();
    remaining.shuffle();
    
    final diverse = remaining.take((scoredFeeds.length * 0.3).round()).toList();
    
    return [...personalized, ...diverse];
  }

  /// 피드 점수 계산
  double _calculateFeedScore(Map<String, dynamic> feed) {
    double score = 0.0;
    
    // 장르 점수
    if (feed['genre'] != null) {
      score += (_userPreferences[feed['genre']] ?? 0) * _genreWeight;
    }
    
    // 태그 점수
    if (feed['tags'] != null) {
      for (String tag in feed['tags']) {
        score += (_userPreferences[tag] ?? 0) * _interestWeight;
      }
    }
    
    // 인기도 점수 (좋아요, 댓글 수 기반)
    final likes = feed['likes'] ?? 0;
    final comments = feed['comments'] ?? 0;
    final popularityScore = (likes + comments * 2) / 100.0; // 정규화
    score += popularityScore * _popularityWeight;
    
    // 시간 가중치 (최신 피드에 더 높은 점수)
    final hoursAgo = _getHoursAgo(feed['timestamp'] ?? '1시간 전');
    final timeWeight = max(0.1, 1.0 - hoursAgo / 24.0); // 24시간 내 피드에 가중치
    score *= timeWeight;
    
    return score;
  }

  /// 시간 차이 계산 (시간 단위)
  int _getHoursAgo(String timestamp) {
    if (timestamp.contains('방금 전')) return 0;
    if (timestamp.contains('분 전')) {
      final minutes = int.tryParse(timestamp.replaceAll('분 전', '')) ?? 0;
      return minutes ~/ 60;
    }
    if (timestamp.contains('시간 전')) {
      return int.tryParse(timestamp.replaceAll('시간 전', '')) ?? 1;
    }
    if (timestamp.contains('일 전')) {
      final days = int.tryParse(timestamp.replaceAll('일 전', '')) ?? 1;
      return days * 24;
    }
    return 24; // 기본값
  }

  /// 추천 이유 생성
  String getRecommendationReason(Map<String, dynamic> feed) {
    final reasons = <String>[];
    
    if (feed['genre'] != null && _userPreferences[feed['genre']] != null) {
      reasons.add('${feed['genre']} 장르를 좋아하시네요');
    }
    
    if (feed['tags'] != null) {
      for (String tag in feed['tags']) {
        if (_userPreferences[tag] != null && _userPreferences[tag]! > 0.3) {
          reasons.add('$tag에 관심이 많으시네요');
          break;
        }
      }
    }
    
    if (reasons.isEmpty) {
      reasons.add('새로운 음악을 발견해보세요');
    }
    
    return reasons.first;
  }

  /// 사용자 선호도 분석 결과
  Map<String, dynamic> getUserPreferenceAnalysis() {
    final sortedPreferences = _userPreferences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return {
      'topGenres': sortedPreferences.where((e) => _isGenre(e.key)).take(3).map((e) => e.key).toList(),
      'topInstruments': sortedPreferences.where((e) => _isInstrument(e.key)).take(3).map((e) => e.key).toList(),
      'topInterests': sortedPreferences.where((e) => !_isGenre(e.key) && !_isInstrument(e.key)).take(3).map((e) => e.key).toList(),
      'totalPreferences': _userPreferences.length,
    };
  }

  /// 추천 정확도 개선을 위한 피드백
  Future<void> provideFeedback(String feedId, String action, bool isPositive) async {
    // 사용자 피드백을 기반으로 추천 알고리즘 개선
    // 실제 구현에서는 더 정교한 피드백 시스템 필요
    print('피드백 기록: $feedId, $action, $isPositive');
  }
} 