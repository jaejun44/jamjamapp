import 'supabase_service.dart';

/// 북마크(피드 저장) 서비스 — Supabase bookmarks 테이블 연동
class BookmarkService {
  BookmarkService._internal();
  static final BookmarkService instance = BookmarkService._internal();

  /// bookmarks + feeds 조인 결과를 화면에서 쓸 Map으로 변환
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
      'bookmarkedAt': row['created_at'] ?? '',
    };
  }

  /// 내 북마크 피드 목록
  Future<List<Map<String, dynamic>>> getBookmarkedFeeds() async {
    final rows = await SupabaseService.instance.getBookmarkedFeeds();
    return rows.map(_mapRow).toList();
  }

  /// 북마크 추가
  Future<void> bookmark(String feedId) =>
      SupabaseService.instance.bookmarkFeed(feedId);

  /// 북마크 제거
  Future<void> unbookmark(String feedId) =>
      SupabaseService.instance.unbookmarkFeed(feedId);

  /// 북마크 여부 확인
  Future<bool> isBookmarked(String feedId) =>
      SupabaseService.instance.isBookmarked(feedId);
}
