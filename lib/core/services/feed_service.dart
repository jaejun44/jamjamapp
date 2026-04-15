import 'dart:typed_data';
import 'package:jamjamapp/core/services/supabase_service.dart';
import 'package:jamjamapp/core/services/auth_state_manager.dart';

/// 피드 데이터 서비스
/// Supabase feeds 테이블 CRUD 및 UI 데이터 매핑 담당
class FeedService {
  static final FeedService _instance = FeedService._internal();
  factory FeedService() => _instance;
  FeedService._internal();

  static FeedService get instance => _instance;

  // ---------------------------------------------------------------------------
  // 내부 유틸
  // ---------------------------------------------------------------------------

  /// Supabase UUID → 세션 내 안정적 int ID 변환
  int _uuidToInt(String uuid) => uuid.hashCode.abs();

  /// ISO8601 타임스탬프 → 사람이 읽기 편한 문자열
  String _formatTimestamp(String? isoString) {
    if (isoString == null) return '방금 전';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return '방금 전';
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      if (diff.inDays < 7) return '${diff.inDays}일 전';
      return '${dt.month}월 ${dt.day}일';
    } catch (_) {
      return '방금 전';
    }
  }

  /// Supabase 행 → UI에서 쓰는 피드 Map
  Map<String, dynamic> _mapRow(Map<String, dynamic> row) {
    final supabaseId = row['id'] as String;
    final intId = _uuidToInt(supabaseId);
    final profiles = row['profiles'] as Map<String, dynamic>?;
    final nickname = (profiles?['nickname'] as String?)?.isNotEmpty == true
        ? profiles!['nickname'] as String
        : (profiles?['username'] as String? ?? 'Unknown');
    final avatarUrl = profiles?['avatar_url'] as String?;

    final rawMediaUrls = row['media_urls'];
    final mediaUrls = rawMediaUrls is List
        ? rawMediaUrls.map((e) => e.toString()).toList()
        : <String>[];
    final mediaUrl = mediaUrls.isNotEmpty ? mediaUrls.first : null;

    String mediaType = 'text';
    if (mediaUrl != null) {
      final lower = mediaUrl.toLowerCase();
      if (lower.contains('.mp4') || lower.contains('.mov')) {
        mediaType = 'video';
      } else if (lower.contains('.mp3') || lower.contains('.wav') || lower.contains('.aac')) {
        mediaType = 'audio';
      } else if (lower.contains('.jpg') || lower.contains('.jpeg') ||
                 lower.contains('.png') || lower.contains('.gif')) {
        mediaType = 'image';
      }
    }

    final content = row['content'] as String? ?? '';
    // 첫 줄을 제목으로 사용
    final lines = content.split('\n');
    final title = lines.first;
    final body = lines.length > 1 ? lines.skip(1).join('\n') : content;

    return {
      'id': intId,
      'supabaseId': supabaseId,
      'authorId': row['user_id'] as String?,
      'author': nickname,
      'authorAvatar': avatarUrl ?? '🎵',
      'title': title,
      'content': body,
      'genre': '일반',
      'likes': (row['likes_count'] as int?) ?? 0,
      'comments': (row['comments_count'] as int?) ?? 0,
      'shares': 0,
      'timestamp': _formatTimestamp(row['created_at'] as String?),
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      'mediaData': null,
      'tags': <String>[],
    };
  }

  // ---------------------------------------------------------------------------
  // 공개 API
  // ---------------------------------------------------------------------------

  /// Supabase에서 피드 목록 가져오기
  Future<List<Map<String, dynamic>>> fetchFeeds({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final rows = await SupabaseService.instance.getFeedData(
        limit: limit,
        offset: offset,
      );
      return rows.map(_mapRow).toList();
    } catch (_) {
      return [];
    }
  }

  /// Supabase에 피드 생성, 실패 시 null 반환
  Future<Map<String, dynamic>?> createFeed({
    required String content,
    String? title,
    String mediaType = 'text',
    String? mediaUrl,
    Uint8List? mediaData,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return null;

    try {
      final fullContent =
          (title != null && title.isNotEmpty) ? '$title\n$content' : content;

      // mediaData가 있으면 Storage에 업로드 후 URL 획득
      String? resolvedUrl = mediaUrl;
      if (mediaData != null && mediaType != 'text') {
        resolvedUrl = await SupabaseService.instance.uploadMedia(
          userId: userId,
          fileBytes: mediaData,
          mediaType: mediaType,
        );
      }

      await SupabaseService.instance.createFeed(
        userId: userId,
        content: fullContent,
        mediaUrls: resolvedUrl != null ? [resolvedUrl] : null,
      );
    } catch (_) {
      // 생성 실패 — 로컬 피드는 이미 표시됨, 조용히 무시
    }

    // 즉각 표시용 임시 로컬 피드 반환
    return {
      'id': DateTime.now().millisecondsSinceEpoch,
      'supabaseId': null,
      'author': AuthStateManager.instance.userName,
      'authorAvatar': AuthStateManager.instance.avatarUrl ?? '👤',
      'title': title ?? '',
      'content': content,
      'genre': '일반',
      'likes': 0,
      'comments': 0,
      'shares': 0,
      'timestamp': '방금 전',
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      'mediaData': mediaData,
      'tags': <String>[],
    };
  }

  /// 내 피드 목록 가져오기
  Future<List<Map<String, dynamic>>> getMyFeeds() async {
    try {
      final rows = await SupabaseService.instance.getMyFeeds();
      return rows.map(_mapRow).toList();
    } catch (_) {
      return [];
    }
  }

  /// Supabase에서 피드 삭제 (논블로킹)
  Future<void> deleteFeed(String supabaseId) async {
    try {
      await SupabaseService.instance.deleteFeed(supabaseId);
    } catch (_) {}
  }

  /// Supabase에서 피드 콘텐츠 업데이트 (논블로킹)
  Future<void> updateFeed(String supabaseId, {String? content}) async {
    if (content == null) return;
    try {
      await SupabaseService.instance.updateFeedContent(
        feedId: supabaseId,
        content: content,
      );
    } catch (_) {}
  }
}
