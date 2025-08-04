import 'package:flutter/material.dart';
import 'package:jamjamapp/core/services/comment_service.dart';
import 'package:jamjamapp/core/services/auth_state_manager.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';

class CommentModal extends StatefulWidget {
  final int feedId;
  final String feedTitle;

  const CommentModal({
    Key? key,
    required this.feedId,
    required this.feedTitle,
  }) : super(key: key);

  @override
  State<CommentModal> createState() => _CommentModalState();
}

class _CommentModalState extends State<CommentModal> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _nestedReplyController = TextEditingController();
  final TextEditingController _editCommentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  int? _replyingToCommentId;
  int? _replyingToReplyId;
  int? _editingCommentId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    _nestedReplyController.dispose();
    _editCommentController.dispose();
    super.dispose();
  }

  /// 댓글 수정 모드 토글
  void _toggleEditMode(int commentId, String currentContent) {
    setState(() {
      if (_editingCommentId == commentId) {
        _editingCommentId = null;
        _editCommentController.clear();
      } else {
        _editingCommentId = commentId;
        _editCommentController.text = currentContent;
      }
    });
  }

  /// 댓글 수정 완료
  Future<void> _updateComment(int commentId) async {
    if (_editCommentController.text.trim().isEmpty) return;

    // 로그인 상태 확인
    if (!AuthStateManager.instance.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 또는 회원가입이 필요합니다.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await CommentService.instance.updateComment(commentId, _editCommentController.text.trim());
      _editCommentController.clear();
      _editingCommentId = null;
      _loadComments();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('댓글이 수정되었습니다!'),
          backgroundColor: AppTheme.accentPink,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('댓글 수정 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  /// 댓글 로드
  void _loadComments() {
    setState(() {
      _comments = CommentService.instance.getCommentsForFeed(widget.feedId);
    });
  }

  /// 댓글 추가
  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    // 로그인 상태 확인
    if (!AuthStateManager.instance.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 또는 회원가입이 필요합니다.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await CommentService.instance.addComment(widget.feedId, _commentController.text.trim());
      _commentController.clear();
      _loadComments();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('댓글이 추가되었습니다!'),
          backgroundColor: AppTheme.accentPink,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('댓글 추가 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  /// 댓글 좋아요 토글
  Future<void> _toggleCommentLike(int commentId) async {
    try {
      await CommentService.instance.toggleCommentLike(commentId);
      _loadComments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('좋아요 처리 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 답글 입력 표시 토글
  void _toggleReplyInput(int commentId) {
    setState(() {
      if (_replyingToCommentId == commentId) {
        _replyingToCommentId = null;
        _replyController.clear();
      } else {
        _replyingToCommentId = commentId;
        _replyController.clear();
      }
    });
  }

  /// 답글 추가
  Future<void> _addReply(int commentId) async {
    if (_replyController.text.trim().isEmpty) return;

    // 로그인 상태 확인
    if (!AuthStateManager.instance.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 또는 회원가입이 필요합니다.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await CommentService.instance.addReply(commentId, _replyController.text.trim());
      _replyController.clear();
      _replyingToCommentId = null;
      _loadComments();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('답글이 추가되었습니다!'),
          backgroundColor: AppTheme.accentPink,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('답글 추가 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  /// 중첩 답글 표시 토글
  void _toggleNestedReplyInput(int replyId) {
    setState(() {
      if (_replyingToReplyId == replyId) {
        _replyingToReplyId = null;
        _nestedReplyController.clear();
      } else {
        _replyingToReplyId = replyId;
        _nestedReplyController.clear();
      }
    });
  }

  /// 중첩 답글 추가
  Future<void> _addNestedReply(int replyId) async {
    if (_nestedReplyController.text.trim().isEmpty) return;

    // 로그인 상태 확인
    if (!AuthStateManager.instance.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 또는 회원가입이 필요합니다.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await CommentService.instance.addNestedReply(replyId, _nestedReplyController.text.trim());
      _nestedReplyController.clear();
      _replyingToReplyId = null;
      _loadComments();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('답글이 추가되었습니다!'),
          backgroundColor: AppTheme.accentPink,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('답글 추가 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  /// 답글 좋아요 토글
  Future<void> _toggleReplyLike(int replyId) async {
    try {
      await CommentService.instance.toggleReplyLike(replyId);
      _loadComments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('좋아요 처리 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 중첩 답글 좋아요 토글
  Future<void> _toggleNestedReplyLike(int nestedReplyId) async {
    try {
      await CommentService.instance.toggleNestedReplyLike(nestedReplyId);
      _loadComments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('좋아요 처리 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUserProfile(String username) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('프로필 보기: $username'),
        backgroundColor: AppTheme.accentPink,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 댓글 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(int commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('댓글 삭제'),
          content: const Text('정말로 이 댓글을 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                try {
                  await CommentService.instance.deleteComment(commentId);
                  _loadComments();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('댓글이 삭제되었습니다!'),
                      backgroundColor: AppTheme.accentPink,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('댓글 삭제 중 오류가 발생했습니다: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  /// 댓글 신고 다이얼로그
  void _showReportDialog(int commentId, String authorName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryBlack,
          title: Text(
            '댓글 신고',
            style: TextStyle(color: AppTheme.white),
          ),
          content: Text(
            '$authorName님의 댓글을 신고하시겠습니까?',
            style: TextStyle(color: AppTheme.white),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소', style: TextStyle(color: AppTheme.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$authorName님의 댓글이 신고되었습니다.'),
                    backgroundColor: AppTheme.accentPink,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Text('신고', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.secondaryBlack,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.grey, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: AppTheme.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '댓글 (${_comments.length})',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppTheme.white),
                    ),
                  ],
                ),
              ),
              
              // 댓글 입력
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.grey, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.accentPink,
                      backgroundImage: AuthStateManager.instance.profileImageBytes != null
                          ? MemoryImage(AuthStateManager.instance.profileImageBytes!)
                          : null,
                      child: AuthStateManager.instance.profileImageBytes != null
                          ? null
                          : const Icon(Icons.person, color: AppTheme.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: '댓글을 입력하세요...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: AppTheme.grey),
                        ),
                        style: const TextStyle(color: AppTheme.white),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _addComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _addComment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentPink,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: _isSubmitting 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                              ),
                            )
                          : const Text('댓글', style: TextStyle(color: AppTheme.white)),
                    ),
                  ],
                ),
              ),
              
              // 댓글 목록
              Expanded(
                child: _comments.isEmpty
                    ? const Center(
                        child: Text(
                          '아직 댓글이 없습니다.\n첫 번째 댓글을 남겨보세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.grey,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          return _buildCommentCard(_comments[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메인 댓글
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showUserProfile(comment['author']),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.accentPink,
                  backgroundImage: comment['author'] == AuthStateManager.instance.userName && 
                                  AuthStateManager.instance.profileImageBytes != null
                      ? MemoryImage(AuthStateManager.instance.profileImageBytes!)
                      : null,
                  child: comment['author'] == AuthStateManager.instance.userName && 
                         AuthStateManager.instance.profileImageBytes != null
                      ? null
                      : const Icon(Icons.person, color: AppTheme.white, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showUserProfile(comment['author']),
                          child: Text(
                            comment['author'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comment['timestamp'],
                          style: const TextStyle(
                            color: AppTheme.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment['content'],
                      style: const TextStyle(color: AppTheme.white),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleCommentLike(comment['id']),
                          child: Row(
                            children: [
                              Icon(
                                comment['isLiked'] ? Icons.favorite : Icons.favorite_border,
                                size: 16,
                                color: comment['isLiked'] ? AppTheme.accentPink : AppTheme.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${comment['likes']}',
                                style: TextStyle(
                                  color: comment['isLiked'] ? AppTheme.accentPink : AppTheme.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _toggleReplyInput(comment['id']),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.reply,
                                size: 16,
                                color: AppTheme.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '답글',
                                style: const TextStyle(
                                  color: AppTheme.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 댓글 작성자만 삭제 버튼 표시
                        if (comment['author'] == AuthStateManager.instance.userName)
                          GestureDetector(
                            onTap: () => _showDeleteConfirmDialog(comment['id']),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: AppTheme.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '삭제',
                                  style: const TextStyle(
                                    color: AppTheme.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 16),
                        // 댓글 작성자만 수정 버튼 표시
                        if (comment['author'] == AuthStateManager.instance.userName)
                          GestureDetector(
                            onTap: () => _toggleEditMode(comment['id'], comment['content']),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: AppTheme.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '수정',
                                  style: const TextStyle(
                                    color: AppTheme.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 16),
                        // 신고 버튼 (자신의 댓글이 아닌 경우만)
                        if (comment['author'] != AuthStateManager.instance.userName)
                          GestureDetector(
                            onTap: () => _showReportDialog(comment['id'], comment['author']),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.flag_outlined,
                                  size: 16,
                                  color: AppTheme.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '신고',
                                  style: const TextStyle(
                                    color: AppTheme.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 16),
                        // 신고 버튼 (자신의 댓글이 아닌 경우만)
                        if (comment['author'] != AuthStateManager.instance.userName)
                          GestureDetector(
                            onTap: () => _showReportDialog(comment['id'], comment['author']),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.flag_outlined,
                                  size: 16,
                                  color: AppTheme.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '신고',
                                  style: const TextStyle(
                                    color: AppTheme.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // 답글 입력 필드
          if (_replyingToCommentId == comment['id'])
            Container(
              margin: const EdgeInsets.only(top: 8, left: 44),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _replyController,
                    decoration: const InputDecoration(
                      hintText: '답글을 입력하세요...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppTheme.grey),
                    ),
                    style: const TextStyle(color: AppTheme.white),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addReply(comment['id']),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _toggleReplyInput(comment['id']),
                        child: const Text('취소', style: TextStyle(color: AppTheme.grey)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _addReply(comment['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentPink,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: _isSubmitting 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                ),
                              )
                            : const Text('답글', style: TextStyle(color: AppTheme.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          // 댓글 수정 입력 필드
          if (_editingCommentId == comment['id'])
            Container(
              margin: const EdgeInsets.only(top: 8, left: 44),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentPink.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _editCommentController,
                    decoration: const InputDecoration(
                      hintText: '댓글을 수정하세요...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppTheme.grey),
                    ),
                    style: const TextStyle(color: AppTheme.white),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _updateComment(comment['id']),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _toggleEditMode(comment['id'], ''),
                        child: const Text('취소', style: TextStyle(color: AppTheme.grey)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _updateComment(comment['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentPink,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: _isSubmitting 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                ),
                              )
                            : const Text('수정', style: TextStyle(color: AppTheme.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          // 답글 목록 표시
          if (comment['replies'] != null && (comment['replies'] as List).isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8, left: 44),
              child: Column(
                children: (comment['replies'] as List<Map<String, dynamic>>).map((reply) => 
                  _buildReplyCard(reply, comment['id'])
                ).toList(),
              ),
            ),
        ],
      ),
    );
  }

  /// 답글 카드 위젯
  Widget _buildReplyCard(Map<String, dynamic> reply, int parentCommentId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showUserProfile(reply['author']),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.accentPink,
                  backgroundImage: reply['author'] == AuthStateManager.instance.userName && 
                                  AuthStateManager.instance.profileImageBytes != null
                      ? MemoryImage(AuthStateManager.instance.profileImageBytes!)
                      : null,
                  child: reply['author'] == AuthStateManager.instance.userName && 
                         AuthStateManager.instance.profileImageBytes != null
                      ? null
                      : const Icon(Icons.person, color: AppTheme.white, size: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showUserProfile(reply['author']),
                          child: Text(
                            reply['author'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          reply['timestamp'],
                          style: const TextStyle(
                            color: AppTheme.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reply['content'],
                      style: const TextStyle(color: AppTheme.white, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleReplyLike(reply['id']),
                          child: Row(
                            children: [
                              Icon(
                                reply['isLiked'] ? Icons.favorite : Icons.favorite_border,
                                size: 12,
                                color: reply['isLiked'] ? AppTheme.accentPink : AppTheme.grey,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${reply['likes']}',
                                style: TextStyle(
                                  color: reply['isLiked'] ? AppTheme.accentPink : AppTheme.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _toggleNestedReplyInput(reply['id']),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.reply,
                                size: 12,
                                color: AppTheme.grey,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '답글',
                                style: const TextStyle(
                                  color: AppTheme.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // 중첩 답글 목록 표시
          if (reply['nestedReplies'] != null && (reply['nestedReplies'] as List).isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8, left: 20),
              child: Column(
                children: (reply['nestedReplies'] as List<Map<String, dynamic>>).map((nestedReply) => 
                  _buildNestedReplyCard(nestedReply, reply['id'])
                ).toList(),
              ),
            ),
          
          // 중첩 답글 입력 필드
          if (_replyingToReplyId == reply['id'])
            Container(
              margin: const EdgeInsets.only(top: 8, left: 20),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nestedReplyController,
                    decoration: const InputDecoration(
                      hintText: '답글을 입력하세요...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppTheme.grey, fontSize: 12),
                    ),
                    style: const TextStyle(color: AppTheme.white, fontSize: 12),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addNestedReply(reply['id']),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _toggleNestedReplyInput(reply['id']),
                        child: const Text('취소', style: TextStyle(color: AppTheme.grey, fontSize: 10)),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _addNestedReply(reply['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentPink,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: _isSubmitting 
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                ),
                              )
                            : const Text('답글', style: TextStyle(color: AppTheme.white, fontSize: 10)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 중첩 답글 카드 위젯
  Widget _buildNestedReplyCard(Map<String, dynamic> nestedReply, int parentReplyId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showUserProfile(nestedReply['author']),
            child: CircleAvatar(
              radius: 8,
              backgroundColor: AppTheme.accentPink,
              backgroundImage: nestedReply['author'] == AuthStateManager.instance.userName && 
                              AuthStateManager.instance.profileImageBytes != null
                  ? MemoryImage(AuthStateManager.instance.profileImageBytes!)
                  : null,
              child: nestedReply['author'] == AuthStateManager.instance.userName && 
                     AuthStateManager.instance.profileImageBytes != null
                  ? null
                  : const Icon(Icons.person, color: AppTheme.white, size: 8),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showUserProfile(nestedReply['author']),
                      child: Text(
                        nestedReply['author'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      nestedReply['timestamp'],
                      style: const TextStyle(
                        color: AppTheme.grey,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  nestedReply['content'],
                  style: const TextStyle(color: AppTheme.white, fontSize: 10),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleNestedReplyLike(nestedReply['id']),
                      child: Row(
                        children: [
                          Icon(
                            nestedReply['isLiked'] ? Icons.favorite : Icons.favorite_border,
                            size: 8,
                            color: nestedReply['isLiked'] ? AppTheme.accentPink : AppTheme.grey,
                          ),
                          const SizedBox(width: 1),
                          Text(
                            '${nestedReply['likes']}',
                            style: TextStyle(
                              color: nestedReply['isLiked'] ? AppTheme.accentPink : AppTheme.grey,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 