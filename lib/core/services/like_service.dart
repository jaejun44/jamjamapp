import 'supabase_service.dart';

/// 피드 좋아요 서비스 — Supabase feed_likes 테이블 연동
class LikeService {
  LikeService._internal();
  static final LikeService instance = LikeService._internal();

  /// feed_likes + feeds 조인 결과를 화면에서 쓸 Map으로 변환
  Map<String, dynamic> _mapRow(Map<String, dynamic> row) {
    final feed = row['feeds'] as Map<String, dynamic>? ?? {};
    return {
      'id': feed['id'] ?? '',
      'title': feed['title'] ?? '',
      'content': feed['content'] ?? '',
      'author': feed['user_id'] ?? '',
      'authorId': feed['user_id'] ?? '',
      'mediaUrl': feed['media_url'],
      'likes': feed['likes_count'] ?? 0,
      'likedAt': row['created_at'] ?? '',
    };
  }

  /// 내가 좋아요 한 피드 목록
  Future<List<Map<String, dynamic>>> getLikedFeeds() async {
    final rows = await SupabaseService.instance.getLikedFeeds();
    return rows.map(_mapRow).toList();
  }

  /// 좋아요 추가
  Future<void> like(String feedId) =>
      SupabaseService.instance.likeFeed(feedId);

  /// 좋아요 취소
  Future<void> unlike(String feedId) =>
      SupabaseService.instance.unlikeFeed(feedId);

  /// 좋아요 여부 확인
  Future<bool> isLiked(String feedId) =>
      SupabaseService.instance.isFeedLiked(feedId);
}
