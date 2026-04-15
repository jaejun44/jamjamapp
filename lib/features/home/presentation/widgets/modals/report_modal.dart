import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';

class ReportModal extends StatefulWidget {
  final Map<String, dynamic> feed;

  const ReportModal({
    super.key,
    required this.feed,
  });

  @override
  State<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal> {
  String _selectedReason = '';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _reportReasons = [
    {
      'id': 'spam',
      'title': '스팸 또는 광고',
      'description': '상업적 목적의 반복적인 게시물',
      'icon': Icons.block,
    },
    {
      'id': 'inappropriate',
      'title': '부적절한 콘텐츠',
      'description': '폭력적이거나 성적인 콘텐츠',
      'icon': Icons.warning,
    },
    {
      'id': 'copyright',
      'title': '저작권 침해',
      'description': '무단 사용된 저작물',
      'icon': Icons.copyright,
    },
    {
      'id': 'harassment',
      'title': '괴롭힘 또는 폭력',
      'description': '타인을 괴롭히는 콘텐츠',
      'icon': Icons.report_problem,
    },
    {
      'id': 'fake',
      'title': '허위 정보',
      'description': '사실과 다른 정보',
      'icon': Icons.fact_check,
    },
    {
      'id': 'other',
      'title': '기타',
      'description': '기타 신고 사유',
      'icon': Icons.more_horiz,
    },
  ];

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
          _buildHeader(),
          const SizedBox(height: 24),
          
          // 신고할 피드 정보
          _buildFeedInfo(),
          const SizedBox(height: 24),
          
          // 신고 사유 선택
          _buildReasonSelection(),
          const SizedBox(height: 24),
          
          // 추가 설명 (기타 선택 시)
          if (_selectedReason == 'other') ...[
            _buildAdditionalDetails(),
            const SizedBox(height: 24),
          ],
          
          // 신고 버튼
          _buildSubmitButton(),
        ],
      ),
    );
  }

  /// 헤더 빌드
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '피드 신고',
          style: TextStyle(
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
    );
  }

  /// 피드 정보 빌드
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
                radius: 16,
                backgroundColor: AppTheme.accentPink,
                child: _buildSafeAvatarText(widget.feed['authorAvatar']),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.feed['author'] ?? '작성자',
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 14,
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
            const SizedBox(height: 8),
            Text(
              widget.feed['title'],
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 16,
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 신고 사유 선택
  Widget _buildReasonSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '신고 사유를 선택해주세요',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...(_reportReasons.map((reason) => _buildReasonOption(reason))),
      ],
    );
  }

  /// 신고 사유 옵션
  Widget _buildReasonOption(Map<String, dynamic> reason) {
    final isSelected = _selectedReason == reason['id'];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReason = reason['id'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentPink.withValues(alpha: 0.2) : AppTheme.primaryBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentPink : AppTheme.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              reason['icon'],
              color: isSelected ? AppTheme.accentPink : AppTheme.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason['title'],
                    style: TextStyle(
                      color: isSelected ? AppTheme.accentPink : AppTheme.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    reason['description'],
                    style: TextStyle(
                      color: isSelected ? AppTheme.accentPink.withValues(alpha: 0.8) : AppTheme.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.accentPink,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  /// 추가 설명 입력
  Widget _buildAdditionalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '추가 설명 (선택사항)',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (_) {},
          style: const TextStyle(color: AppTheme.white),
          maxLines: 4,
          decoration: InputDecoration(
            hintText: '신고 사유에 대한 자세한 설명을 입력해주세요...',
            hintStyle: const TextStyle(color: AppTheme.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.accentPink),
            ),
            filled: true,
            fillColor: AppTheme.primaryBlack,
          ),
        ),
      ],
    );
  }

  /// 신고 제출 버튼
  Widget _buildSubmitButton() {
    final isValid = _selectedReason.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isValid && !_isSubmitting ? _submitReport : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid ? Colors.red : AppTheme.grey.withValues(alpha: 0.3),
          foregroundColor: AppTheme.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppTheme.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text('신고 처리 중...'),
              ],
            )
          : const Text('신고하기'),
      ),
    );
  }

  /// 신고 제출
  Future<void> _submitReport() async {
    if (_selectedReason.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    // 시뮬레이션된 신고 처리 시간
    await Future.delayed(const Duration(seconds: 2));

    // 신고 처리 (실제로는 서버에 전송)

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    // 성공 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('신고가 성공적으로 접수되었습니다. 검토 후 조치하겠습니다.'),
        backgroundColor: AppTheme.accentPink,
        duration: Duration(seconds: 3),
      ),
    );

    Navigator.of(context).pop();
  }

/// 안전하게 아바타 텍스트를 빌드합니다.
  Widget _buildSafeAvatarText(dynamic avatar) {
    if (avatar is String) {
      return Text(
        avatar,
        style: const TextStyle(fontSize: 12),
      );
    } else {
      // MemoryImage 등 복잡한 타입인 경우 기본 아이콘 표시
      return const Text(
        '👤',
        style: TextStyle(fontSize: 12),
      );
    }
  }
} 