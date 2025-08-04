import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jamjamapp/core/services/app_state_manager.dart';
import 'package:jamjamapp/core/services/auth_state_manager.dart';

class CommentService {
  static final CommentService _instance = CommentService._internal();
  static CommentService get instance => _instance;
  CommentService._internal();

  /// 댓글 추가
  Future<void> addComment(int feedId, String content) async {
    print('🔍 댓글 추가 시작 - 피드 ID: $feedId, 내용: $content');
    
    final comment = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'feedId': feedId,
      'author': AuthStateManager.instance.userName,
      'content': content,
      'timestamp': '방금 전',
      'likes': 0,
      'isLiked': false,
      'replies': <Map<String, dynamic>>[],
    };

    // AppStateManager에 댓글 추가
    final commentData = Map<String, List<Map<String, dynamic>>>.from(
      AppStateManager.instance.getState('comments')['commentData'] ?? {}
    );
    
    print('🔍 현재 저장된 댓글 데이터 키들: ${commentData.keys.toList()}');
    
    if (commentData[feedId.toString()] == null) {
      commentData[feedId.toString()] = <Map<String, dynamic>>[];
      print('🔍 새로운 피드 댓글 배열 생성: ${feedId.toString()}');
    }
    
    commentData[feedId.toString()]!.add(comment);
    print('🔍 댓글 추가됨 - 피드 ${feedId.toString()}: ${commentData[feedId.toString()]!.length}개');
    
    // 상태 저장
    await AppStateManager.instance.updateValue('comments', 'commentData', commentData);
    
    print('✅ 댓글 추가 완료: 피드 $feedId (총 ${commentData[feedId.toString()]!.length}개)');
  }

  /// 답글 추가
  Future<void> addReply(int commentId, String content) async {
    final reply = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'commentId': commentId,
      'author': AuthStateManager.instance.userName,
      'content': content,
      'timestamp': '방금 전',
      'likes': 0,
      'isLiked': false,
    };

    // AppStateManager에 답글 추가
    final replyData = Map<String, List<Map<String, dynamic>>>.from(
      AppStateManager.instance.getState('comments')['replyData'] ?? {}
    );
    
    if (replyData[commentId.toString()] == null) {
      replyData[commentId.toString()] = <Map<String, dynamic>>[];
    }
    
    replyData[commentId.toString()]!.add(reply);
    
    // 상태 저장
    await AppStateManager.instance.updateValue('comments', 'replyData', replyData);
    
    print('✅ 답글 추가 완료: 댓글 $commentId');
  }

  /// 댓글 삭제
  Future<void> deleteComment(int commentId) async {
    final commentData = Map<String, List<Map<String, dynamic>>>.from(
      AppStateManager.instance.getState('comments')['commentData'] ?? {}
    );
    
    // 모든 피드에서 해당 댓글 찾아서 삭제
    for (final feedId in commentData.keys) {
      final comments = List<Map<String, dynamic>>.from(commentData[feedId]!);
      comments.removeWhere((comment) => comment['id'] == commentId);
      commentData[feedId] = comments;
    }
    
    // 상태 저장
    await AppStateManager.instance.updateValue('comments', 'commentData', commentData);
    
    print('✅ 댓글 삭제 완료: 댓글 $commentId');
  }

  /// 댓글 수정
  Future<void> updateComment(int commentId, String newContent) async {
    final commentData = Map<String, List<Map<String, dynamic>>>.from(
      AppStateManager.instance.getState('comments')['commentData'] ?? {}
    );
    
    // 모든 피드에서 해당 댓글 찾아서 수정
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
    
    // 상태 저장
    await AppStateManager.instance.updateValue('comments', 'commentData', commentData);
    
    print('✅ 댓글 수정 완료: 댓글 $commentId');
  }

  /// 피드별 댓글 가져오기
  List<Map<String, dynamic>> getCommentsForFeed(int feedId) {
    final commentData = AppStateManager.instance.getState('comments')['commentData'] ?? {};
    print('🔍 댓글 데이터 조회 - 피드 ID: $feedId');
    print('🔍 저장된 댓글 데이터 키들: ${commentData.keys.toList()}');
    
    final comments = (commentData[feedId.toString()] as List<Map<String, dynamic>>?) ?? [];
    print('🔍 찾은 댓글 수: ${comments.length}');
    
    // 각 댓글에 답글과 중첩 답글 추가
    for (final comment in comments) {
      final replyData = AppStateManager.instance.getState('comments')['replyData'] ?? {};
      final replies = (replyData[comment['id'].toString()] as List<Map<String, dynamic>>?) ?? [];
      
      // 각 답글에 중첩 답글 추가
      for (final reply in replies) {
        final nestedReplyData = AppStateManager.instance.getState('comments')['nestedReplyData'] ?? {};
        final nestedReplies = (nestedReplyData[reply['id'].toString()] as List<Map<String, dynamic>>?) ?? [];
        reply['nestedReplies'] = nestedReplies;
      }
      
      comment['replies'] = replies;
    }
    
    print('✅ 댓글 로드 완료 - 피드 $feedId: ${comments.length}개');
    return comments;
  }

  /// 댓글 좋아요 토글
  Future<void> toggleCommentLike(int commentId) async {
    final commentData = Map<String, List<Map<String, dynamic>>>.from(
      AppStateManager.instance.getState('comments')['commentData'] ?? {}
    );
    
    // 모든 피드에서 해당 댓글 찾아서 좋아요 토글
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
    
    // 상태 저장
    await AppStateManager.instance.updateValue('comments', 'commentData', commentData);
    
    print('✅ 댓글 좋아요 토글 완료: 댓글 $commentId');
  }

  /// 댓글 수 가져오기
  int getCommentCount(int feedId) {
    final commentData = AppStateManager.instance.getState('comments')['commentData'] ?? {};
    final comments = (commentData[feedId.toString()] as List<Map<String, dynamic>>?) ?? [];
    
    // 실제 댓글 수 반환
    return comments.length;
  }

  /// 중첩 답글 추가
  Future<void> addNestedReply(int replyId, String content) async {
    final nestedReply = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'replyId': replyId,
      'author': AuthStateManager.instance.userName,
      'content': content,
      'timestamp': '방금 전',
      'likes': 0,
      'isLiked': false,
    };

    // AppStateManager에 중첩 답글 추가
    final nestedReplyData = Map<String, List<Map<String, dynamic>>>.from(
      AppStateManager.instance.getState('comments')['nestedReplyData'] ?? {}
    );
    
    if (nestedReplyData[replyId.toString()] == null) {
      nestedReplyData[replyId.toString()] = <Map<String, dynamic>>[];
    }
    
    nestedReplyData[replyId.toString()]!.add(nestedReply);
    
    // 상태 저장
    await AppStateManager.instance.updateValue('comments', 'nestedReplyData', nestedReplyData);
    
    print('✅ 중첩 답글 추가 완료: 답글 $replyId');
  }

  /// 답글 좋아요 토글
  Future<void> toggleReplyLike(int replyId) async {
    final replyData = Map<String, List<Map<String, dynamic>>>.from(
      AppStateManager.instance.getState('comments')['replyData'] ?? {}
    );
    
    // 모든 댓글에서 해당 답글 찾아서 좋아요 토글
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
    
    // 상태 저장
    await AppStateManager.instance.updateValue('comments', 'replyData', replyData);
    
    print('✅ 답글 좋아요 토글 완료: 답글 $replyId');
  }

  /// 중첩 답글 좋아요 토글
  Future<void> toggleNestedReplyLike(int nestedReplyId) async {
    final nestedReplyData = Map<String, List<Map<String, dynamic>>>.from(
      AppStateManager.instance.getState('comments')['nestedReplyData'] ?? {}
    );
    
    // 모든 답글에서 해당 중첩 답글 찾아서 좋아요 토글
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
    
    // 상태 저장
    await AppStateManager.instance.updateValue('comments', 'nestedReplyData', nestedReplyData);
    
    print('✅ 중첩 답글 좋아요 토글 완료: 중첩 답글 $nestedReplyId');
  }
} 