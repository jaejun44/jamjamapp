import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'user_profile_screen.dart';

class CommentModal extends StatefulWidget {
  final int feedIndex;

  const CommentModal({
    super.key,
    required this.feedIndex,
  });

  @override
  State<CommentModal> createState() => _CommentModalState();
}

class _CommentModalState extends State<CommentModal> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // 임시 댓글 데이터
  final List<Map<String, dynamic>> _comments = [
    {
      'id': 1,
      'author': 'MusicLover2',
      'content': '정말 멋진 음악이네요! 🎵',
      'likes': 5,
      'isLiked': false,
      'timestamp': '5분 전',
    },
    {
      'id': 2,
      'author': 'GuitarHero3',
      'content': '기타 연주가 인상적입니다 👍',
      'likes': 12,
      'isLiked': true,
      'timestamp': '10분 전',
    },
    {
      'id': 3,
      'author': 'Pianist4',
      'content': '함께 연주하고 싶어요!',
      'likes': 3,
      'isLiked': false,
      'timestamp': '15분 전',
    },
    {
      'id': 4,
      'author': 'Drummer5',
      'content': '드럼 파트가 정말 좋네요 🥁',
      'likes': 8,
      'isLiked': false,
      'timestamp': '20분 전',
    },
  ];

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;

    final newComment = {
      'id': _comments.length + 1,
      'author': '나',
      'content': _commentController.text.trim(),
      'likes': 0,
      'isLiked': false,
      'timestamp': '방금 전',
    };

    setState(() {
      _comments.insert(0, newComment);
    });

    _commentController.clear();

    // 스크롤을 맨 위로
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('댓글이 추가되었습니다!'),
        backgroundColor: AppTheme.accentPink,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _toggleLike(int commentId) {
    setState(() {
      final comment = _comments.firstWhere((c) => c['id'] == commentId);
      comment['isLiked'] = !comment['isLiked'];
      comment['likes'] += comment['isLiked'] ? 1 : -1;
    });
  }

  void _showUserProfile(String username) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(username: username),
      ),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '댓글',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${_comments.length}개의 댓글',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppTheme.white),
                    ),
                  ],
                ),
              ),
              
              // 댓글 목록
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    return _buildCommentCard(_comments[index]);
                  },
                ),
              ),
              
              // 댓글 입력
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTheme.grey, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: '댓글을 입력하세요...',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _addComment(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _addComment,
                      icon: const Icon(
                        Icons.send,
                        color: AppTheme.accentPink,
                      ),
                    ),
                  ],
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showUserProfile(comment['author']),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.accentPink,
              child: const Icon(Icons.person, color: AppTheme.white, size: 16),
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
                      onTap: () => _toggleLike(comment['id']),
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
                      onTap: () {
                        // TODO: 답글 기능
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('답글 기능 준비 중'),
                            backgroundColor: AppTheme.accentPink,
                          ),
                        );
                      },
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