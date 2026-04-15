import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/auth_state_manager.dart';
import 'package:jamjamapp/core/services/profile_image_manager.dart';

class ParticipantCard extends StatelessWidget {
  final Map<String, dynamic> participant;
  final Map<String, dynamic>? jamSession;
  final VoidCallback onShowProfile;
  final VoidCallback? onKick;

  const ParticipantCard({
    super.key,
    required this.participant,
    this.jamSession,
    required this.onShowProfile,
    this.onKick,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthStateManager.instance.userName;
    final isCurrentUser = participant['name'] == currentUser;
    final isHost = participant['role'] == '방장';
    final canKick = jamSession != null &&
        !isCurrentUser &&
        !isHost &&
        jamSession!['participantsList'].any(
          (p) => p['name'] == currentUser && p['role'] == '방장',
        );

    return Card(
      color: AppTheme.primaryBlack,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onLongPress: canKick ? onKick : null,
        child: ListTile(
          leading: Stack(
            children: [
              participant['name'] == AuthStateManager.instance.userName
                  ? ProfileImageManager.instance.buildProfileImage(
                      radius: 20,
                      placeholder: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.accentPink,
                        child: Text(
                          participant['avatar'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.accentPink,
                      child: Text(
                        participant['avatar'],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
              if (participant['isOnline'])
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryBlack, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Text(participant['name'], style: const TextStyle(color: AppTheme.white)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: participant['role'] == '방장'
                      ? AppTheme.accentPink
                      : AppTheme.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  participant['role'],
                  style: TextStyle(
                    color: participant['role'] == '방장' ? AppTheme.white : AppTheme.grey,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '악기: ${participant['instruments'].join(', ')}',
                style: const TextStyle(color: AppTheme.grey),
              ),
              Text(
                '참여: ${participant['joinTime']}',
                style: const TextStyle(color: AppTheme.grey, fontSize: 10),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canKick)
                const Icon(Icons.touch_app, color: AppTheme.grey, size: 16),
              IconButton(
                onPressed: onShowProfile,
                icon: const Icon(Icons.person, color: AppTheme.accentPink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
