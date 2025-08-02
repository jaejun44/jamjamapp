import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';

class ShareModal extends StatefulWidget {
  final Map<String, dynamic> feed;

  const ShareModal({
    super.key,
    required this.feed,
  });

  @override
  State<ShareModal> createState() => _ShareModalState();
}

class _ShareModalState extends State<ShareModal> {
  String _selectedShareType = 'link';

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
              const Text(
                '피드 공유',
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
          ),
          const SizedBox(height: 24),
          
          // 피드 미리보기
          _buildFeedPreview(),
          const SizedBox(height: 24),
          
          // 공유 타입 선택
          _buildShareTypeSelector(),
          const SizedBox(height: 24),
          
          // 공유 옵션들
          _buildShareOptions(),
          const SizedBox(height: 24),
          
          // 공유 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _shareFeed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPink,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('공유하기'),
            ),
          ),
        ],
      ),
    );
  }

  /// 피드 미리보기
  Widget _buildFeedPreview() {
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
                child: Text(
                  widget.feed['authorAvatar'] ?? '👤',
                  style: const TextStyle(fontSize: 12),
                ),
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

  /// 공유 타입 선택
  Widget _buildShareTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '공유 방식',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildShareTypeOption(
                'link',
                '링크',
                Icons.link,
                '피드 링크 공유',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildShareTypeOption(
                'screenshot',
                '스크린샷',
                Icons.screenshot,
                '피드 스크린샷',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildShareTypeOption(
                'embed',
                '임베드',
                Icons.code,
                '임베드 코드',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 공유 타입 옵션
  Widget _buildShareTypeOption(String type, String title, IconData icon, String subtitle) {
    final isSelected = _selectedShareType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedShareType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentPink : AppTheme.primaryBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.accentPink : AppTheme.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.white : AppTheme.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.white : AppTheme.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? AppTheme.white.withValues(alpha: 0.8) : AppTheme.grey.withValues(alpha: 0.7),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 공유 옵션들
  Widget _buildShareOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '공유 대상',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildShareOption('copy', '링크 복사', Icons.copy),
            _buildShareOption('twitter', '트위터', Icons.flutter_dash),
            _buildShareOption('facebook', '페이스북', Icons.facebook),
            _buildShareOption('instagram', '인스타그램', Icons.camera_alt),
            _buildShareOption('whatsapp', '왓츠앱', Icons.chat),
            _buildShareOption('email', '이메일', Icons.email),
            _buildShareOption('sms', 'SMS', Icons.sms),
            _buildShareOption('more', '더보기', Icons.more_horiz),
          ],
        ),
      ],
    );
  }

  /// 공유 옵션
  Widget _buildShareOption(String type, String title, IconData icon) {
    return GestureDetector(
      onTap: () => _shareTo(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 피드 공유
  void _shareFeed() {
    final shareType = _selectedShareType;
    final feedTitle = widget.feed['title'] ?? '피드';
    final feedAuthor = widget.feed['author'] ?? '작성자';
    
    String shareMessage = '';
    
    switch (shareType) {
      case 'link':
        shareMessage = 'JamJam에서 ${feedAuthor}의 "${feedTitle}" 피드를 확인해보세요! 🎵';
        break;
      case 'screenshot':
        shareMessage = '${feedAuthor}의 "${feedTitle}" 피드 스크린샷을 공유합니다! 📸';
        break;
      case 'embed':
        shareMessage = '${feedAuthor}의 "${feedTitle}" 피드 임베드 코드를 공유합니다! 🔗';
        break;
    }

    // 시뮬레이션된 공유
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(shareMessage),
        backgroundColor: AppTheme.accentPink,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '복사',
          textColor: AppTheme.white,
          onPressed: () {
            // 클립보드에 복사 (실제로는 clipboard 패키지 사용)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('클립보드에 복사되었습니다!'),
                backgroundColor: AppTheme.accentPink,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );

    Navigator.of(context).pop();
  }

  /// 특정 플랫폼으로 공유
  void _shareTo(String platform) {
    final feedTitle = widget.feed['title'] ?? '피드';
    final feedAuthor = widget.feed['author'] ?? '작성자';
    
    String message = '';
    String platformName = '';
    
    switch (platform) {
      case 'copy':
        message = '링크가 클립보드에 복사되었습니다!';
        platformName = '클립보드';
        break;
      case 'twitter':
        message = '트위터로 공유되었습니다!';
        platformName = '트위터';
        break;
      case 'facebook':
        message = '페이스북으로 공유되었습니다!';
        platformName = '페이스북';
        break;
      case 'instagram':
        message = '인스타그램으로 공유되었습니다!';
        platformName = '인스타그램';
        break;
      case 'whatsapp':
        message = '왓츠앱으로 공유되었습니다!';
        platformName = '왓츠앱';
        break;
      case 'email':
        message = '이메일로 공유되었습니다!';
        platformName = '이메일';
        break;
      case 'sms':
        message = 'SMS로 공유되었습니다!';
        platformName = 'SMS';
        break;
      case 'more':
        message = '더 많은 공유 옵션이 표시됩니다!';
        platformName = '더보기';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$platformName: $message'),
        backgroundColor: AppTheme.accentPink,
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 