import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';

/// Connect 화면에서 사용하는 뮤지션 카드 위젯
/// 좋아요(♥) / 패스(✕) 버튼으로 인터랙션
class MusicianCardWidget extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onLike;
  final VoidCallback onPass;

  const MusicianCardWidget({
    super.key,
    required this.user,
    required this.onLike,
    required this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    final nickname = user['nickname'] as String? ?? 'Unknown';
    final username = user['username'] as String? ?? '';
    final avatarUrl = user['avatarUrl'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentPink.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 프로필 이미지
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              height: 260,
              width: double.infinity,
              color: AppTheme.accentPink.withValues(alpha: 0.15),
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultAvatar(nickname),
                    )
                  : _defaultAvatar(nickname),
            ),
          ),

          // 이름 / 유저네임
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (username.isNotEmpty)
                  Text(
                    '@$username',
                    style: const TextStyle(
                      color: AppTheme.grey,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),

          // 좋아요 / 패스 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Row(
              children: [
                // 패스
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPass,
                    icon: const Icon(Icons.close, color: AppTheme.grey),
                    label: const Text('패스',
                        style: TextStyle(color: AppTheme.grey)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.grey),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 좋아요
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onLike,
                    icon: const Icon(Icons.favorite, color: AppTheme.white),
                    label: const Text('좋아요',
                        style: TextStyle(color: AppTheme.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPink,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppTheme.accentPink.withValues(alpha: 0.8),
          fontSize: 80,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
