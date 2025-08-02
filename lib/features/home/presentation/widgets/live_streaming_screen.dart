import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'dart:async';

class LiveStreamingScreen extends StatefulWidget {
  final Map<String, dynamic> stream;

  const LiveStreamingScreen({
    super.key,
    required this.stream,
  });

  @override
  State<LiveStreamingScreen> createState() => _LiveStreamingScreenState();
}

class _LiveStreamingScreenState extends State<LiveStreamingScreen> {
  bool _isLive = true;
  bool _isFollowing = false;
  bool _isLiked = false;
  int _viewerCount = 0;
  int _likeCount = 0;
  List<Map<String, dynamic>> _comments = [];
  TextEditingController _commentController = TextEditingController();
  Timer? _viewerTimer;
  Timer? _likeTimer;

  @override
  void initState() {
    super.initState();
    _startLiveSimulation();
    _loadInitialComments();
  }

  @override
  void dispose() {
    _viewerTimer?.cancel();
    _likeTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  /// 라이브 시뮬레이션 시작
  void _startLiveSimulation() {
    // 시청자 수 시뮬레이션
    _viewerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _viewerCount = 150 + (DateTime.now().second % 50);
        });
      }
    });

    // 좋아요 수 시뮬레이션
    _likeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _likeCount += (DateTime.now().second % 3) + 1;
        });
      }
    });
  }

  /// 초기 댓글 로드
  void _loadInitialComments() {
    _comments = [
      {
        'id': 1,
        'user': 'MusicLover1',
        'avatar': '🎵',
        'message': '정말 멋진 연주네요!',
        'timestamp': '방금 전',
      },
      {
        'id': 2,
        'user': 'JazzFan',
        'avatar': '🎷',
        'message': '재즈 팝 퓨전이 완벽해요!',
        'timestamp': '1분 전',
      },
      {
        'id': 3,
        'user': 'GuitarPlayer',
        'avatar': '🎸',
        'message': '기타 솔로 부분이 인상적이에요',
        'timestamp': '2분 전',
      },
    ];
  }

  /// 댓글 추가
  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;

    final newComment = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'user': '나',
      'avatar': '👤',
      'message': _commentController.text.trim(),
      'timestamp': '방금 전',
    };

    setState(() {
      _comments.insert(0, newComment);
    });

    _commentController.clear();

    // 댓글 입력 필드 포커스 해제
    FocusScope.of(context).unfocus();
  }

  /// 좋아요 토글
  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likeCount++;
      } else {
        _likeCount--;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLiked ? '좋아요를 눌렀습니다!' : '좋아요를 취소했습니다.'),
        backgroundColor: AppTheme.accentPink,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// 팔로우 토글
  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFollowing ? '팔로우했습니다!' : '언팔로우했습니다.'),
        backgroundColor: AppTheme.accentPink,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            // 라이브 스트림 비디오 영역
            _buildVideoArea(),
            
            // 컨트롤 영역
            _buildControls(),
            
            // 댓글 영역
            Expanded(
              child: _buildComments(),
            ),
          ],
        ),
      ),
    );
  }

  /// 비디오 영역
  Widget _buildVideoArea() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          // 비디오 플레이스홀더
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam,
                  size: 80,
                  color: AppTheme.accentPink,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.stream['title'] ?? '라이브 스트림',
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.stream['author'] ?? '스트리머',
                  style: const TextStyle(
                    color: AppTheme.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // 라이브 표시
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 시청자 수
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.remove_red_eye,
                    color: AppTheme.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_viewerCount',
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 닫기 버튼
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: AppTheme.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 컨트롤 영역
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 스트리머 정보
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.accentPink,
                  child: Text(
                    widget.stream['authorAvatar'] ?? '👤',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.stream['author'] ?? '스트리머',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.stream['genre'] ?? '음악',
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
          ),
          
          // 팔로우 버튼
          GestureDetector(
            onTap: _toggleFollow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isFollowing ? AppTheme.grey.withValues(alpha: 0.3) : AppTheme.accentPink,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isFollowing ? AppTheme.grey : AppTheme.accentPink,
                ),
              ),
              child: Text(
                _isFollowing ? '팔로잉' : '팔로우',
                style: TextStyle(
                  color: _isFollowing ? AppTheme.grey : AppTheme.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 좋아요 버튼
          GestureDetector(
            onTap: _toggleLike,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlack,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : AppTheme.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_likeCount',
                    style: TextStyle(
                      color: _isLiked ? Colors.red : AppTheme.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 댓글 영역
  Widget _buildComments() {
    return Column(
      children: [
        // 댓글 헤더
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text(
                '실시간 댓글',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentPink,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_comments.length}',
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // 댓글 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.accentPink,
                      child: Text(
                        comment['avatar'],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                comment['user'],
                                style: const TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                comment['timestamp'],
                                style: const TextStyle(
                                  color: AppTheme.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment['message'],
                            style: const TextStyle(
                              color: AppTheme.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // 댓글 입력
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.secondaryBlack,
            border: Border(
              top: BorderSide(color: AppTheme.grey.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: AppTheme.white),
                  decoration: InputDecoration(
                    hintText: '댓글을 입력하세요...',
                    hintStyle: const TextStyle(color: AppTheme.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.primaryBlack,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _addComment(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addComment,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentPink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send,
                    color: AppTheme.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 