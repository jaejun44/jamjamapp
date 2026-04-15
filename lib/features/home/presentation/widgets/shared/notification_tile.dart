import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';

/// 알림 목록에서 사용하는 개별 알림 타일
class NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = notification['type'] as String? ?? '';
    final payload = notification['payload'] as Map<String, dynamic>? ?? {};
    final isRead = notification['read'] as bool? ?? false;

    return ListTile(
      onTap: onTap,
      tileColor: isRead
          ? AppTheme.primaryBlack
          : AppTheme.accentPink.withValues(alpha: 0.08),
      leading: CircleAvatar(
        backgroundColor: AppTheme.accentPink.withValues(alpha: 0.2),
        child: Icon(
          _iconFor(type),
          color: AppTheme.accentPink,
          size: 20,
        ),
      ),
      title: Text(
        _titleFor(type, payload),
        style: TextStyle(
          color: AppTheme.white,
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: _buildSubtitle(payload),
      trailing: isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.accentPink,
                shape: BoxShape.circle,
              ),
            ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'match':
        return Icons.people;
      case 'comment':
        return Icons.comment;
      case 'follow':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  String _titleFor(String type, Map<String, dynamic> payload) {
    final actor = payload['actorNickname'] as String? ?? '누군가';
    switch (type) {
      case 'like':
        return '$actor님이 회원님의 게시물을 좋아합니다';
      case 'match':
        return '$actor님과 매칭이 성사되었습니다!';
      case 'comment':
        return '$actor님이 댓글을 남겼습니다';
      case 'follow':
        return '$actor님이 팔로우하기 시작했습니다';
      default:
        return '새 알림이 있습니다';
    }
  }

  Widget? _buildSubtitle(Map<String, dynamic> payload) {
    final preview = payload['preview'] as String?;
    if (preview == null || preview.isEmpty) return null;
    return Text(
      preview,
      style: const TextStyle(color: AppTheme.grey, fontSize: 12),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
