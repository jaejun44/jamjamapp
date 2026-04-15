import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/auth_state_manager.dart';
import 'package:jamjamapp/core/services/profile_image_manager.dart';

class JamSessionCard extends StatelessWidget {
  final Map<String, dynamic> jamSession;
  final VoidCallback onJoin;
  final VoidCallback onShowDetails;
  final VoidCallback onShowProfile;

  const JamSessionCard({
    super.key,
    required this.jamSession,
    required this.onJoin,
    required this.onShowDetails,
    required this.onShowProfile,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case '모집중':
        return Colors.blue;
      case '진행 중':
        return Colors.green;
      case '완료':
        return Colors.grey;
      default:
        return AppTheme.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final participantsList = List<Map<String, dynamic>>.from(jamSession['participantsList'] ?? []);
    final actualParticipants = participantsList.length;

    return Card(
      color: AppTheme.secondaryBlack,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onShowProfile,
                  child: jamSession['createdBy'] == AuthStateManager.instance.userName
                      ? ProfileImageManager.instance.buildProfileImage(
                          radius: 20,
                          placeholder: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.accentPink,
                            child: const Icon(Icons.person, color: AppTheme.white, size: 20),
                          ),
                        )
                      : const CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.accentPink,
                          child: Icon(Icons.person, color: AppTheme.white, size: 20),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jamSession['title'],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: onShowProfile,
                        child: Text(
                          '${jamSession['createdBy']} • ${jamSession['createdAt']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(jamSession['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    jamSession['status'],
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              jamSession['description'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.white),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 4,
              children: jamSession['tags'].take(3).map<Widget>((tag) {
                return Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 10)),
                  backgroundColor: AppTheme.accentPink.withValues(alpha: 0.2),
                  labelStyle: const TextStyle(color: AppTheme.accentPink),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.music_note, size: 16, color: AppTheme.grey),
                const SizedBox(width: 4),
                Text(
                  jamSession['genre'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.grey),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: AppTheme.grey),
                const SizedBox(width: 4),
                Text(
                  '$actualParticipants/${jamSession['maxParticipants']} 참여',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.grey),
                ),
                const SizedBox(width: 16),
                Icon(Icons.piano, size: 16, color: AppTheme.grey),
                const SizedBox(width: 4),
                Text(
                  jamSession['instruments'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onJoin,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentPink,
                      side: const BorderSide(color: AppTheme.accentPink),
                    ),
                    child: const Text('참여 신청'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onShowDetails,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink),
                    child: const Text('상세 보기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
