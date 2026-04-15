import 'connect_service.dart';

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

/// 사용자 선호도 업데이트
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    _userPreferences.addAll(preferences);
    
    // TODO: 실제 데이터베이스에 저장
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// 추천 사용자 목록 생성 (ConnectService 후보 기반)
  Future<List<Map<String, dynamic>>> getRecommendedUsers({
    required String currentUserId,
    int limit = 10,
  }) async {
    final candidates = await ConnectService.instance.getCandidates();
    return candidates.take(limit).map((c) => {
      'id': c['userId'] as String? ?? '',
      'name': (c['nickname'] as String?)?.isNotEmpty == true
          ? c['nickname'] as String
          : c['username'] as String? ?? 'Unknown',
      'genres': <String>[],
      'instruments': <String>[],
      'activity_level': 'medium',
      'location': '',
      'recommendation_score': 1.0,
    }).toList();
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