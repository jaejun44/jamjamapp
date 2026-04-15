import 'dart:collection';
import 'package:jamjamapp/core/services/app_state_manager.dart';
import 'package:jamjamapp/core/services/auth_state_manager.dart';
import 'package:jamjamapp/core/services/supabase_service.dart';

class CommentService {
  static final CommentService _instance = CommentService._internal();
  static CommentService get instance => _instance;
  CommentService._internal();

  // ---------------------------------------------------------------------------
  // ID 매핑 사전 (로컬 int ID ↔ Supabase UUID)
  // ---------------------------------------------------------------------------

  /// localFeedId → supabase feed UUID
  final Map<int, String> _feedIdToSupabaseId = {};

  /// localCommentId → supabase comment UUID
  final Map<int, String> _commentIdToSupabaseId = {};

  /// localCommentId → 해당 댓글이 속한 localFeedId
  final Map<int, int> _commentIdToLocalFeedId = {};

  // ---------------------------------------------------------------------------
  // 내부 유틸
  // ---------------------------------------------------------------------------

  int _uuidToInt(String uuid) => uuid.hashCode.abs();

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

  Map<String, dynamic> _mapCommentRow(Map<String, dynamic> row) {
    final supabaseId = row['id'] as String;
    final intId = _uuidToInt(supabaseId);
    final profiles = row['profiles'] as Map<String, dynamic>?;
    final nickname = (profiles?['nickname'] as String?)?.isNotEmpty == true
        ? profiles!['nickname'] as String
        : (profiles?['username'] as String? ?? 'Unknown');

    return {
      'id': intId,
      'supabaseId': supabaseId,
      'parentSupabaseId': row['parent_id'] as String?,
      'author': nickname,
      'authorAvatar': profiles?['avatar_url'] as String?,
      'content': row['content'] as String? ?? '',
      'timestamp': _formatTimestamp(row['created_at'] as String?),
      'likes': (row['likes'] as int?) ?? 0,
      'isLiked': false,
      'replies': <Map<String, dynamic>>[],
    };
  }

  // ---------------------------------------------------------------------------
  // Supabase 연동
  // ---------------------------------------------------------------------------

  /// Supabase에서 댓글 전체를 로드해 AppStateManager + 매핑 사전을 채운다.
  Future<void> loadFromSupabase(String supabaseFeedId, int localFeedId) async {
    try {
      _feedIdToSupabaseId[localFeedId] = supabaseFeedId;

      final rows = await SupabaseService.instance.getComments(supabaseFeedId);
      final mapped = rows.map(_mapCommentRow).toList();

      // 모든 댓글 UUID 등록
      for (final c in mapped) {
        final intId = c['id'] as int;
        _commentIdToSupabaseId[intId] = c['supabaseId'] as String;
        _commentIdToLocalFeedId[intId] = localFeedId;
      }

      // UUID → intId 빠른 조회용 맵
      final uuidToInt = <String, int>{};
      for (final c in mapped) {
        uuidToInt[c['supabaseId'] as String] = c['id'] as int;
      }

      // 3레벨 분류
      final topLevel = <Map<String, dynamic>>[];
      final replyLevel = <Map<String, dynamic>>[];
      final nestedLevel = <Map<String, dynamic>>[];

      for (final c in mapped) {
        final parentUuid = c['parentSupabaseId'] as String?;
        if (parentUuid == null) {
          topLevel.add(c);
        } else {
          final parentIntId = uuidToInt[parentUuid];
          if (parentIntId != null && topLevel.any((t) => t['id'] == parentIntId)) {
            replyLevel.add(c);
          } else {
            nestedLevel.add(c);
          }
        }
      }

      // AppStateManager commentData 업데이트
      final commentData = LinkedHashMap<String, List<Map<String, dynamic>>>.from(
        AppStateManager.instance.getState('comments')['commentData'] ?? {},
      );
      commentData[localFeedId.toString()] = topLevel;
      await AppStateManager.instance.updateValue('comments', 'commentData', commentData);

      // AppStateManager replyData 업데이트
      final replyData = Map<String, List<Map<String, dynamic>>>.from(
        AppStateManager.instance.getState('comments')['replyData'] ?? {},
      );
      for (final reply in replyLevel) {
        final parentUuid = reply['parentSupabaseId'] as String;
        final parentIntId = uuidToInt[parentUuid];
        if (parentIntId != null) {
          replyData[parentIntId.toString()] ??= [];
          replyData[parentIntId.toString()]!.add(reply);
        }
      }
      await AppStateManager.instance.updateValue('comments', 'replyData', replyData);

      // AppStateManager nestedReplyData 업데이트
      final nestedReplyData = Map<String, List<Map<String, dynamic>>>.from(
        AppStateManager.instance.getState('comments')['nestedReplyData'] ?? {},
      );
      for (final nested in nestedLevel) {
        final parentUuid = nested['parentSupabaseId'] as String;
        final parentIntId = uuidToInt[parentUuid];
        if (parentIntId != null) {
          nestedReplyData[parentIntId.toString()] ??= [];
          nestedReplyData[parentIntId.toString()]!.add(nested);
        }
      }
      await AppStateManager.instance.updateValue('comments', 'nestedReplyData', nestedReplyData);
    } catch (_) {
      // Supabase 실패 시 기존 로컬 상태 유지
    }
  }

  // ---------------------------------------------------------------------------
  // 공개 API
  // ---------------------------------------------------------------------------

  /// 댓글 추가
  Future<void> addComment(int feedId, String content) async {
    final localId = DateTime.now().millisecondsSinceEpoch;
    final comment = {
      'id': localId,
      'supabaseId': null,
      'feedId': feedId,
      'author': AuthStateManager.instance.userName,
      'content': content,
      'timestamp': '방금 전',
      'likes': 0,
      'isLiked': false,
      'replies': <Map<String, dynamic>>[],
    };

    final commentData = LinkedHashMap<String, List<Map<String, dynamic>>>.from(
      AppStateManager.instance.getState('comments')['commentData'] ?? {},
    );
    commentData[feedId.toString()] ??= [];
    commentData[feedId.toString()]!.add(comment);
    await AppStateManager.instance.updateValue('comments', 'commentData', commentData);

    // Supabase 비동기 insert
    final supabaseFeedId = _feedIdToSupabaseId[feedId];
    final authorId = SupabaseService.instance.currentUser?.id;
    if (supabaseFeedId != null && authorId != null) {
      SupabaseService.instance.addComment(
        feedId: supabaseFeedId,
        authorId: authorId,
        content: content,
      ).then((row) {
        final supabaseId = row['id'] as String;
        _commentIdToSupabaseId[localId] = supabaseId;
        _commentIdToLocalFeedId[localId] = feedId;
      }).catchError((_) {});
    }
  }

  /// 답글 추가
  Future<void> addReply(int commentId, String content) async {
    final localId = DateTime.now().millisecondsSinceEpoch;
    final reply = {
      'id': localId,
      'supabaseId': null,
      'commentId': commentId,
      'author': AuthStateManager.instance.userName,
      'content': content,
      'timestamp': '방금 전',
      'likes': 0,
      'isLiked': false,
    };

    final replyData = Map<String, List<Map<String, dynamic>>>.from(
      AppStateManager.instance.getState('comments')['replyData'] ?? {},
    );
    replyData[commentId.toString()] ??= [];
    replyData[commentId.toString()]!.add(reply);
    await AppStateManager.instance.updateValue('comments', 'replyData', replyData);

    // Supabase 비동기 insert
    final parentSupabaseId = _commentIdToSupabaseId[commentId];
    final localFeedId = _commentIdToLocalFeedId[commentId];
    final supabaseFeedId = localFeedId != null ? _feedIdToSupabaseId[localFeedId] : null;
    final authorId = SupabaseService.instance.currentUser?.id;
    if (parentSupabaseId != null && supabaseFeedId != null && authorId != null) {
      SupabaseService.instance.addComment(
        feedId: supabaseFeedId,
        authorId: authorId,
        content: content,
        parentId: parentSupabaseId,
      ).then((row) {
        final supabaseId = row['id'] as String;
        _commentIdToSupabaseId[localId] = supabaseId;
        if (localFeedId != null) _commentIdToLocalFeedId[localId] = localFeedId;
      }).catchError((_) {});
    }
  }

  /// 중첩 답글 추가
  Future<void> addNestedReply(int replyId, String content) async {
    final localId = DateTime.now().millisecondsSinceEpoch;
    final nestedReply = {
      'id': localId,
      'supabaseId': null,
      'replyId': replyId,
      'author': AuthStateManager.instance.userName,
      'content': content,
      'timestamp': '방금 전',
      'likes': 0,
      'isLiked': false,
    };

    final nestedReplyData = Map<String, List<Map<String, dynamic>>>.from(
      AppStateManager.instance.getState('comments')['nestedReplyData'] ?? {},
    );
    nestedReplyData[replyId.toString()] ??= [];
    nestedReplyData[replyId.toString()]!.add(nestedReply);
    await AppStateManager.instance.updateValue('comments', 'nestedReplyData', nestedReplyData);

    // Supabase 비동기 insert
    final parentSupabaseId = _commentIdToSupabaseId[replyId];
    final localFeedId = _commentIdToLocalFeedId[replyId];
    final supabaseFeedId = localFeedId != null ? _feedIdToSupabaseId[localFeedId] : null;
    final authorId = SupabaseService.instance.currentUser?.id;
    if (parentSupabaseId != null && supabaseFeedId != null && authorId != null) {
      SupabaseService.instance.addComment(
        feedId: supabaseFeedId,
        authorId: authorId,
        content: content,
        parentId: parentSupabaseId,
      ).then((row) {
        final supabaseId = row['id'] as String;
        _commentIdToSupabaseId[localId] = supabaseId;
        if (localFeedId != null) _commentIdToLocalFeedId[localId] = localFeedId;
      }).catchError((_) {});
    }
  }

  /// 댓글 삭제
  Future<void> deleteComment(int commentId) async {
    final commentData = Map<String, List<Map<String, dynamic>>>.from(
      AppStateManager.instance.getState('comments')['commentData'] ?? {},
    );
    for (final feedId in commentData.keys) {
      final comments = List<Map<String, dynamic>>.from(commentData[feedId]!);
      comments.removeWhere((c) => c['id'] == commentId);
      commentData[feedId] = comments;
    }
    await AppStateManager.instance.updateValue('comments', 'commentData', commentData);

    // Supabase 비동기 delete
    final supabaseId = _commentIdToSupabaseId[commentId];
    if (supabaseId != null) {
      SupabaseService.instance.deleteComment(supabaseId).catchError((_) {});
    }
  }

  /// 댓글 수정
  Future<void> updateComment(int commentId, String newContent) async {
    final commentData = Map<String, List<Map<String, dynamic>>>.from(
      AppStateManager.instance.getState('comments')['commentData'] ?? {},
    );
    for (final feedId in commentData.keys) {
      final comments = List<Map<String, dynamic>>.from(commentData[feedId]!);
      for (final comment in comments) {
        if (comment['id'] == commentId) {
          comment['content'] = newContent;
          comment['timestamp'] = '방금 전 (수정됨)';
          break;
        }
      }
      commentData[feedId] = comments;
    }
    await AppStateManager.instance.updateValue('comments', 'commentData', commentData);

    // Supabase 비동기 update
    final supabaseId = _commentIdToSupabaseId[commentId];
    if (supabaseId != null) {
      SupabaseService.instance.updateCommentContent(
        commentId: supabaseId,
        content: newContent,
      ).catchError((_) {});
    }
  }

  /// 피드별 댓글 가져오기
  List<Map<String, dynamic>> getCommentsForFeed(int feedId) {
    final commentData = AppStateManager.instance.getState('comments')['commentData'] ?? {};
    final comments = (commentData[feedId.toString()] as List<Map<String, dynamic>>?) ?? [];

    for (final comment in comments) {
      final replyData = AppStateManager.instance.getState('comments')['replyData'] ?? {};
      final replies = (replyData[comment['id'].toString()] as List<Map<String, dynamic>>?) ?? [];
      for (final reply in replies) {
        final nestedReplyData = AppStateManager.instance.getState('comments')['nestedReplyData'] ?? {};
        final nestedReplies = (nestedReplyData[reply['id'].toString()] as List<Map<String, dynamic>>?) ?? [];
        reply['nestedReplies'] = nestedReplies;
      }
      comment['replies'] = replies;
    }

    return comments;
  }

  /// 댓글 수 가져오기
  int getCommentCount(int feedId) {
    final commentData = AppStateManager.instance.getState('comments')['commentData'] ?? {};
    final comments = (commentData[feedId.toString()] as List<Map<String, dynamic>>?) ?? [];
    return comments.length;
  }

  /// 댓글 좋아요 토글
  Future<void> toggleCommentLike(int commentId) async {
    final commentData = Map<String, List<Map<String, dynamic>>>.from(
      AppStateManager.instance.getState('comments')['commentData'] ?? {},
    );
    for (final feedId in commentData.keys) {
      final comments = List<Map<String, dynamic>>.from(commentData[feedId]!);
      for (final comment in comments) {
        if (comment['id'] == commentId) {
          comment['isLiked'] = !(comment['isLiked'] ?? false);
          comment['likes'] += comment['isLiked'] ? 1 : -1;
          break;
        }
      }
      commentData[feedId] = comments;
    }
    await AppStateManager.instance.updateValue('comments', 'commentData', commentData);
  }

  /// 답글 좋아요 토글
  Future<void> toggleReplyLike(int replyId) async {
    final replyData = Map<String, List<Map<String, dynamic>>>.from(
      AppStateManager.instance.getState('comments')['replyData'] ?? {},
    );
    for (final commentId in replyData.keys) {
      final replies = List<Map<String, dynamic>>.from(replyData[commentId]!);
      for (final reply in replies) {
        if (reply['id'] == replyId) {
          reply['isLiked'] = !(reply['isLiked'] ?? false);
          reply['likes'] += reply['isLiked'] ? 1 : -1;
          break;
        }
      }
      replyData[commentId] = replies;
    }
    await AppStateManager.instance.updateValue('comments', 'replyData', replyData);
  }

  /// 중첩 답글 좋아요 토글
  Future<void> toggleNestedReplyLike(int nestedReplyId) async {
    final nestedReplyData = Map<String, List<Map<String, dynamic>>>.from(
      AppStateManager.instance.getState('comments')['nestedReplyData'] ?? {},
    );
    for (final replyId in nestedReplyData.keys) {
      final nestedReplies = List<Map<String, dynamic>>.from(nestedReplyData[replyId]!);
      for (final nestedReply in nestedReplies) {
        if (nestedReply['id'] == nestedReplyId) {
          nestedReply['isLiked'] = !(nestedReply['isLiked'] ?? false);
          nestedReply['likes'] += nestedReply['isLiked'] ? 1 : -1;
          break;
        }
      }
      nestedReplyData[replyId] = nestedReplies;
    }
    await AppStateManager.instance.updateValue('comments', 'nestedReplyData', nestedReplyData);
  }
}
