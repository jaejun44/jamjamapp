import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/counter_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

  /// 특정 플랫폼으로 공유 (실제 구현)
  void _shareTo(String platform) async {
    final feedTitle = widget.feed['title'] ?? '피드';
    final feedAuthor = widget.feed['author'] ?? '작성자';
    final feedId = widget.feed['id'] as int;
    
    // 공유할 텍스트 생성
    final shareText = '🎵 JamJam에서 "$feedTitle" by $feedAuthor\n\n'
        '음악을 함께 만들어보세요! #JamJam #음악협업';
    final shareUrl = 'https://jamjam.app/feed/$feedId'; // 실제 앱 URL로 변경 필요
    final fullShareText = '$shareText\n\n$shareUrl';
    
    try {
      switch (platform) {
        case 'copy':
          await _copyToClipboard(shareUrl);
          break;
        case 'twitter':
          await _shareToTwitter(shareText, shareUrl);
          break;
        case 'facebook':
          await _shareToFacebook(shareUrl);
          break;
        case 'instagram':
          await _shareToInstagram(shareText);
          break;
        case 'whatsapp':
          await _shareToWhatsApp(fullShareText);
          break;
        case 'email':
          await _shareToEmail(feedTitle, fullShareText);
          break;
        case 'sms':
          await _shareToSMS(fullShareText);
          break;
        case 'more':
          await _shareGeneral(fullShareText);
          break;
      }
      
      // CounterService에 공유 카운트 증가
      await CounterService.instance.incrementShareCount(feedId);
      
      Navigator.of(context).pop();
    } catch (e) {
      print('❌ 공유 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('공유 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 클립보드에 복사
  Future<void> _copyToClipboard(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('링크가 클립보드에 복사되었습니다!'),
        backgroundColor: AppTheme.accentPink,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 트위터 공유
  Future<void> _shareToTwitter(String text, String url) async {
    final twitterUrl = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}&url=${Uri.encodeComponent(url)}';
    await _launchUrl(twitterUrl, '트위터');
  }

  /// 페이스북 공유
  Future<void> _shareToFacebook(String url) async {
    final facebookUrl = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}';
    await _launchUrl(facebookUrl, '페이스북');
  }

  /// 인스타그램 공유 (텍스트만)
  Future<void> _shareToInstagram(String text) async {
    await Share.share(text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('인스타그램 앱에서 스토리나 포스트로 공유해주세요!'),
        backgroundColor: AppTheme.accentPink,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// 왓츠앱 공유
  Future<void> _shareToWhatsApp(String text) async {
    final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    await _launchUrl(whatsappUrl, '왓츠앱');
  }

  /// 이메일 공유
  Future<void> _shareToEmail(String subject, String body) async {
    final emailUrl = 'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
    await _launchUrl(emailUrl, '이메일');
  }

  /// SMS 공유
  Future<void> _shareToSMS(String text) async {
    final smsUrl = 'sms:?body=${Uri.encodeComponent(text)}';
    await _launchUrl(smsUrl, 'SMS');
  }

  /// 일반 공유 (시스템 공유 시트)
  Future<void> _shareGeneral(String text) async {
    await Share.share(text);
  }

  /// URL 실행
  Future<void> _launchUrl(String url, String platformName) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$platformName으로 공유되었습니다!'),
          backgroundColor: AppTheme.accentPink,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      throw Exception('$platformName을 열 수 없습니다.');
    }
  }
} 