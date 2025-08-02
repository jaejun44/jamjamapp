import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart';
import 'user_profile_screen.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  // 실시간 채팅 데이터
  final List<Map<String, dynamic>> _chatList = [
    {
      'id': 1,
      'userName': 'JamMaster1',
      'userAvatar': '🎸',
      'lastMessage': '안녕하세요! 함께 연주해요 🎵',
      'timestamp': '방금 전',
      'unreadCount': 2,
      'isOnline': true,
      'lastMessageType': 'text',
    },
    {
      'id': 2,
      'userName': 'MusicLover2',
      'userAvatar': '🎹',
      'lastMessage': '피아노 연주 영상 보내드릴게요',
      'timestamp': '5분 전',
      'unreadCount': 0,
      'isOnline': false,
      'lastMessageType': 'media',
    },
    {
      'id': 3,
      'userName': 'GuitarHero3',
      'userAvatar': '🎸',
      'lastMessage': '기타 리프 연습 중입니다 🔥',
      'timestamp': '10분 전',
      'unreadCount': 1,
      'isOnline': true,
      'lastMessageType': 'text',
    },
    {
      'id': 4,
      'userName': 'Pianist4',
      'userAvatar': '🎹',
      'lastMessage': '클래식 연주회 후기 공유해요',
      'timestamp': '30분 전',
      'unreadCount': 0,
      'isOnline': false,
      'lastMessageType': 'text',
    },
    {
      'id': 5,
      'userName': 'Drummer5',
      'userAvatar': '🥁',
      'lastMessage': '드럼 솔로 영상 올렸어요',
      'timestamp': '1시간 전',
      'unreadCount': 3,
      'isOnline': true,
      'lastMessageType': 'media',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        title: const Text('채팅'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('새 메시지 기능 준비 중'),
                  backgroundColor: AppTheme.accentPink,
                ),
              );
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: '채팅 검색...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.grey),
                filled: true,
                fillColor: AppTheme.secondaryBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // 채팅 목록
          Expanded(
            child: ListView.builder(
              itemCount: _chatList.length,
              itemBuilder: (context, index) {
                final chat = _chatList[index];
                return _buildChatItem(context, chat);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, Map<String, dynamic> chat) {
    return ListTile(
      leading: Stack(
        children: [
          GestureDetector(
            onTap: () => _showUserProfile(chat['userName']),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: AppTheme.accentPink,
              child: Text(
                chat['userAvatar'],
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          // 온라인 상태 표시
          if (chat['isOnline'])
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
          GestureDetector(
            onTap: () => _showUserProfile(chat['userName']),
            child: Text(
              chat['userName'],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (chat['lastMessageType'] == 'media')
            const Icon(Icons.attach_file, size: 16, color: AppTheme.grey),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chat['lastMessage'],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            chat['timestamp'],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.grey,
            ),
          ),
        ],
      ),
      trailing: chat['unreadCount'] > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppTheme.accentPink,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${chat['unreadCount']}',
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              userName: chat['userName'],
              userAvatar: chat['userAvatar'],
            ),
          ),
        );
      },
    );
  }

  // 사용자 프로필로 이동
  void _showUserProfile(String username) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(username: username),
      ),
    );
  }
} 