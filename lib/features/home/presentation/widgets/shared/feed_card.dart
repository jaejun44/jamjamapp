import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/auth_state_manager.dart';
import 'media_player_widget.dart';

class FeedCard extends StatelessWidget {
  final Map<String, dynamic> feed;
  final int index;
  final bool isLiked;
  final bool isSaved;
  final bool isFollowed;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;
  final VoidCallback onToggleFollow;
  final VoidCallback onShowComments;
  final VoidCallback onShowShare;
  final VoidCallback onShowOptions;
  final VoidCallback onTapProfile;

  const FeedCard({
    super.key,
    required this.feed,
    required this.index,
    required this.isLiked,
    required this.isSaved,
    required this.isFollowed,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onToggleFollow,
    required this.onShowComments,
    required this.onShowShare,
    required this.onShowOptions,
    required this.onTapProfile,
  });

  Widget _buildSafeAvatarText(dynamic avatar) {
    if (avatar is String) {
      return Text(avatar, style: const TextStyle(fontSize: 16));
    }
    return const Text('👤', style: TextStyle(fontSize: 16));
  }

  Widget _buildMediaContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: MediaPlayerWidget(
        mediaType: feed['mediaType'],
        mediaUrl: feed['mediaUrl'],
        mediaData: feed['mediaData'],
        title: feed['title'] ?? '미디어 콘텐츠',
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isActive ? AppTheme.accentPink : AppTheme.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive ? AppTheme.accentPink : AppTheme.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 피드 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onTapProfile,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.accentPink,
                    backgroundImage: feed['author'] == AuthStateManager.instance.userName &&
                                    AuthStateManager.instance.profileImageBytes != null
                        ? MemoryImage(AuthStateManager.instance.profileImageBytes!)
                        : null,
                    child: feed['author'] == AuthStateManager.instance.userName &&
                           AuthStateManager.instance.profileImageBytes != null
                        ? null
                        : _buildSafeAvatarText(feed['authorAvatar']),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feed['author'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.white,
                        ),
                      ),
                      Text(
                        feed['timestamp'],
                        style: const TextStyle(fontSize: 12, color: AppTheme.grey),
                      ),
                    ],
                  ),
                ),
                if (feed['author'] != '나')
                  GestureDetector(
                    onTap: onToggleFollow,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isFollowed
                            ? AppTheme.grey.withValues(alpha: 0.3)
                            : AppTheme.accentPink,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isFollowed ? AppTheme.grey : AppTheme.accentPink,
                        ),
                      ),
                      child: Text(
                        isFollowed ? '팔로잉' : '팔로우',
                        style: TextStyle(
                          color: isFollowed ? AppTheme.grey : AppTheme.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppTheme.grey),
                  onPressed: onShowOptions,
                ),
              ],
            ),
          ),

          if (feed['title'] != null && feed['title'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                feed['title'],
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              feed['content'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.white),
            ),
          ),

          if (feed['mediaType'] != 'text') _buildMediaContent(),

          // 액션 버튼들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildActionButton(context,
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '${feed['likes']}',
                  isActive: isLiked,
                  onTap: onToggleLike,
                ),
                const SizedBox(width: 24),
                _buildActionButton(context,
                  icon: Icons.chat_bubble_outline,
                  label: '${feed['comments']}',
                  isActive: false,
                  onTap: onShowComments,
                ),
                const SizedBox(width: 24),
                _buildActionButton(context,
                  icon: Icons.share,
                  label: '${feed['shares']}',
                  isActive: false,
                  onTap: onShowShare,
                ),
                const Spacer(),
                _buildActionButton(context,
                  icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                  label: '저장',
                  isActive: isSaved,
                  onTap: onToggleSave,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
