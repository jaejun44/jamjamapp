import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';

class FeedEditModal extends StatefulWidget {
  final Map<String, dynamic> feed;
  final Function(Map<String, dynamic>) onFeedUpdated;
  final Function(int) onFeedDeleted;

  const FeedEditModal({
    super.key,
    required this.feed,
    required this.onFeedUpdated,
    required this.onFeedDeleted,
  });

  @override
  State<FeedEditModal> createState() => _FeedEditModalState();
}

class _FeedEditModalState extends State<FeedEditModal> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _genreController;
  bool _isEditing = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.feed['title'] ?? '');
    _contentController = TextEditingController(text: widget.feed['content'] ?? '');
    _genreController = TextEditingController(text: widget.feed['genre'] ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEditing ? '피드 수정' : '피드 옵션',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppTheme.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (!_isEditing) ...[
            // 피드 정보
            _buildFeedInfo(),
            const SizedBox(height: 24),
            
            // 옵션 버튼들
            _buildOptions(),
          ] else ...[
            // 편집 폼
            _buildEditForm(),
          ],
        ],
      ),
    );
  }

  /// 피드 정보 표시
  Widget _buildFeedInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.accentPink,
                child: Text(
                  widget.feed['authorAvatar'] ?? '👤',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.feed['author'] ?? '작성자',
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.feed['timestamp'] ?? '방금 전',
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
          if (widget.feed['title'] != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.feed['title'],
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            widget.feed['content'] ?? '내용 없음',
            style: const TextStyle(
              color: AppTheme.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.favorite, color: AppTheme.accentPink, size: 16),
              const SizedBox(width: 4),
              Text(
                '${widget.feed['likes'] ?? 0}',
                style: const TextStyle(color: AppTheme.grey, fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble, color: AppTheme.grey, size: 16),
              const SizedBox(width: 4),
              Text(
                '${widget.feed['comments'] ?? 0}',
                style: const TextStyle(color: AppTheme.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 옵션 버튼들
  Widget _buildOptions() {
    final isAuthor = widget.feed['author'] == '나'; // 실제로는 현재 사용자와 비교
    
    return Column(
      children: [
        if (isAuthor) ...[
          // 수정 버튼
          _buildOptionButton(
            '수정',
            Icons.edit,
            () {
              setState(() {
                _isEditing = true;
              });
            },
          ),
          const SizedBox(height: 12),
          
          // 삭제 버튼
          _buildOptionButton(
            '삭제',
            Icons.delete,
            _showDeleteConfirmation,
            isDestructive: true,
          ),
          const SizedBox(height: 12),
        ],
        
        // 공유 버튼
        _buildOptionButton(
          '공유',
          Icons.share,
          () {
            Navigator.of(context).pop();
            // TODO: 공유 기능 호출
          },
        ),
        const SizedBox(height: 12),
        
        // 신고 버튼
        if (!isAuthor)
          _buildOptionButton(
            '신고',
            Icons.report,
            _showReportDialog,
            isDestructive: true,
          ),
      ],
    );
  }

  /// 옵션 버튼
  Widget _buildOptionButton(String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : AppTheme.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? Colors.red : AppTheme.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 편집 폼
  Widget _buildEditForm() {
    return Column(
      children: [
        // 제목 입력
        TextField(
          controller: _titleController,
          style: const TextStyle(color: AppTheme.white),
          decoration: InputDecoration(
            labelText: '제목',
            labelStyle: const TextStyle(color: AppTheme.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.accentPink),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // 내용 입력
        TextField(
          controller: _contentController,
          style: const TextStyle(color: AppTheme.white),
          maxLines: 4,
          decoration: InputDecoration(
            labelText: '내용',
            labelStyle: const TextStyle(color: AppTheme.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.accentPink),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // 장르 입력
        TextField(
          controller: _genreController,
          style: const TextStyle(color: AppTheme.white),
          decoration: InputDecoration(
            labelText: '장르',
            labelStyle: const TextStyle(color: AppTheme.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.accentPink),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // 버튼들
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.grey.withValues(alpha: 0.3),
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPink,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('저장'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 변경사항 저장
  void _saveChanges() {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제목과 내용을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedFeed = Map<String, dynamic>.from(widget.feed);
    updatedFeed['title'] = _titleController.text;
    updatedFeed['content'] = _contentController.text;
    updatedFeed['genre'] = _genreController.text;
    updatedFeed['timestamp'] = '방금 전 (수정됨)';

    widget.onFeedUpdated(updatedFeed);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('피드가 수정되었습니다!'),
        backgroundColor: AppTheme.accentPink,
      ),
    );
  }

  /// 삭제 확인 다이얼로그
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text(
          '피드 삭제',
          style: TextStyle(color: AppTheme.white),
        ),
        content: const Text(
          '정말로 이 피드를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
          style: TextStyle(color: AppTheme.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소', style: TextStyle(color: AppTheme.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteFeed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: AppTheme.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 피드 삭제
  void _deleteFeed() {
    widget.onFeedDeleted(widget.feed['id']);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('피드가 삭제되었습니다.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// 신고 다이얼로그
  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text(
          '피드 신고',
          style: TextStyle(color: AppTheme.white),
        ),
        content: const Text(
          '이 피드를 신고하시겠습니까?\n부적절한 콘텐츠를 신고해주세요.',
          style: TextStyle(color: AppTheme.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소', style: TextStyle(color: AppTheme.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('신고가 접수되었습니다.'),
                  backgroundColor: AppTheme.accentPink,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: AppTheme.white,
            ),
            child: const Text('신고'),
          ),
        ],
      ),
    );
  }
} 