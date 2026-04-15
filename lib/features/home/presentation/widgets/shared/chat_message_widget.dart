import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/auth_state_manager.dart';
import 'package:jamjamapp/core/services/profile_image_manager.dart';

class ChatMessageWidget extends StatelessWidget {
  final Map<String, dynamic> message;

  const ChatMessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message['isMe'] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            message['user'] == AuthStateManager.instance.userName
                ? ProfileImageManager.instance.buildProfileImage(
                    radius: 16,
                    placeholder: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.accentPink,
                      child: Text(
                        message['user'][0],
                        style: const TextStyle(color: AppTheme.white, fontSize: 12),
                      ),
                    ),
                  )
                : CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.accentPink,
                    child: Text(
                      message['user'][0],
                      style: const TextStyle(color: AppTheme.white, fontSize: 12),
                    ),
                  ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.accentPink : AppTheme.primaryBlack,
                borderRadius: BorderRadius.circular(16),
                border: isMe ? null : Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message['user'],
                      style: TextStyle(
                        color: isMe ? AppTheme.white : AppTheme.accentPink,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (!isMe) const SizedBox(height: 4),
                  Text(
                    message['message'],
                    style: const TextStyle(color: AppTheme.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message['time'],
                    style: TextStyle(
                      color: isMe ? AppTheme.white.withValues(alpha: 0.7) : AppTheme.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            ProfileImageManager.instance.buildProfileImage(
              radius: 16,
              placeholder: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.accentPink,
                child: Text(
                  message['user'][0],
                  style: const TextStyle(color: AppTheme.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
