import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class RecommendationService {
  static RecommendationService? _instance;
  static RecommendationService get instance => _instance ??= RecommendationService._internal();
  
  RecommendationService._internal();

  // 사용자 선호도 데이터
  final Map<String, dynamic> _userPreferences = {
    'genres': ['jazz', 'pop', 'rock'],
    'instruments': ['guitar', 'piano'],
    'activity_level': 'high',
  };

  // 추천 알고리즘 가중치
  final Map<String, double> _weights = {
    'genre_match': 0.4,
    'instrument_match': 0.3,
    'activity_match': 0.2,
    'location_match': 0.1,
  };

  /// 사용자 선호도 업데이트
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    _userPreferences.addAll(preferences);
    
    // TODO: 실제 데이터베이스에 저장
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// 추천 점수 계산
  double _calculateRecommendationScore(Map<String, dynamic> user, Map<String, dynamic> target) {
    double score = 0.0;
    
    // 장르 매칭 점수
    final userGenres = List<String>.from(user['genres'] ?? []);
    final targetGenres = List<String>.from(target['genres'] ?? []);
    final genreMatch = _calculateListSimilarity(userGenres, targetGenres);
    score += genreMatch * _weights['genre_match']!;
    
    // 악기 매칭 점수
    final userInstruments = List<String>.from(user['instruments'] ?? []);
    final targetInstruments = List<String>.from(target['instruments'] ?? []);
    final instrumentMatch = _calculateListSimilarity(userInstruments, targetInstruments);
    score += instrumentMatch * _weights['instrument_match']!;
    
    // 활동 수준 매칭
    final userActivity = user['activity_level'] ?? 'medium';
    final targetActivity = target['activity_level'] ?? 'medium';
    final activityMatch = userActivity == targetActivity ? 1.0 : 0.5;
    score += activityMatch * _weights['activity_match']!;
    
    // 위치 매칭 (간단한 구현)
    final userLocation = user['location'] ?? '';
    final targetLocation = target['location'] ?? '';
    final locationMatch = userLocation == targetLocation ? 1.0 : 0.0;
    score += locationMatch * _weights['location_match']!;
    
    return score;
  }

  /// 리스트 유사도 계산
  double _calculateListSimilarity(List<String> list1, List<String> list2) {
    if (list1.isEmpty && list2.isEmpty) return 1.0;
    if (list1.isEmpty || list2.isEmpty) return 0.0;
    
    final intersection = list1.where((item) => list2.contains(item)).length;
    final union = list1.length + list2.length - intersection;
    
    return union > 0 ? intersection / union : 0.0;
  }

  /// 추천 사용자 목록 생성
  Future<List<Map<String, dynamic>>> getRecommendedUsers({
    required String currentUserId,
    int limit = 10,
  }) async {
    // TODO: 실제 데이터베이스에서 사용자 목록 가져오기
    final allUsers = [
      {
        'id': 'user1',
        'name': 'JazzMaster',
        'genres': ['jazz', 'blues'],
        'instruments': ['saxophone', 'piano'],
        'activity_level': 'high',
        'location': 'Seoul',
      },
      {
        'id': 'user2',
        'name': 'PopLover',
        'genres': ['pop', 'rock'],
        'instruments': ['guitar', 'vocals'],
        'activity_level': 'medium',
        'location': 'Busan',
      },
      {
        'id': 'user3',
        'name': 'ClassicalFan',
        'genres': ['classical', 'jazz'],
        'instruments': ['violin', 'piano'],
        'activity_level': 'low',
        'location': 'Seoul',
      },
    ];
    
    // 현재 사용자 정보 (실제로는 데이터베이스에서 가져와야 함)
    final currentUser = {
      'id': currentUserId,
      'genres': _userPreferences['genres'],
      'instruments': _userPreferences['instruments'],
      'activity_level': _userPreferences['activity_level'],
      'location': 'Seoul',
    };
    
    // 추천 점수 계산 및 정렬
    final recommendations = allUsers
        .where((user) => user['id'] != currentUserId)
        .map((user) {
          final score = _calculateRecommendationScore(currentUser, user);
          return {
            ...user,
            'recommendation_score': score,
          };
        })
        .toList();
    
    recommendations.sort((a, b) => 
        (b['recommendation_score'] as double).compareTo(a['recommendation_score'] as double));
    
    return recommendations.take(limit).toList();
  }

  /// 추천 콘텐츠 생성
  Future<List<Map<String, dynamic>>> getRecommendedContent({
    required String userId,
    int limit = 10,
  }) async {
    // TODO: 실제 콘텐츠 추천 알고리즘 구현
    final recommendedUsers = await getRecommendedUsers(currentUserId: userId, limit: 5);
    
    final recommendedContent = <Map<String, dynamic>>[];
    
    for (final user in recommendedUsers) {
      // 해당 사용자의 최근 콘텐츠 가져오기 (시뮬레이션)
      final userContent = [
        {
          'id': 'content_${user['id']}_1',
          'title': '${user['name']}의 새로운 곡',
          'type': 'music',
          'author_id': user['id'],
          'author_name': user['name'],
          'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': 'content_${user['id']}_2',
          'title': '${user['name']}의 Jam 세션',
          'type': 'jam_session',
          'author_id': user['id'],
          'author_name': user['name'],
          'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        },
      ];
      
      recommendedContent.addAll(userContent);
    }
    
    // 최신순으로 정렬
    recommendedContent.sort((a, b) => 
        DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
    
    return recommendedContent.take(limit).toList();
  }

  /// 개인화된 피드 생성
  Future<List<Map<String, dynamic>>> getPersonalizedFeed({
    required String userId,
    int limit = 20,
  }) async {
    final recommendedContent = await getRecommendedContent(userId: userId, limit: limit);
    
    // TODO: 실제 피드 데이터와 혼합
    final personalizedFeed = <Map<String, dynamic>>[];
    
    // 추천 콘텐츠 추가
    for (final content in recommendedContent) {
      personalizedFeed.add({
        ...content,
        'is_recommended': true,
        'recommendation_reason': '사용자 선호도 기반 추천',
      });
    }
    
    return personalizedFeed;
  }
} 