import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/auth_state_manager.dart';
import 'package:jamjamapp/core/services/profile_image_manager.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart';
import 'user_profile_screen.dart';
import 'dart:async';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  // 검색 상태
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredChatList = [];
  
  // 실시간 업데이트 상태
  Timer? _realtimeUpdateTimer;
  bool _isRealtimeUpdateEnabled = true;
  
  // 필터 상태
  String _selectedFilter = '전체';
  final List<String> _filterOptions = ['전체', '온라인', '미읽음', '미디어'];

  // 실시간 채팅 데이터 (확장된 버전)
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
      'isTyping': false,
      'lastSeen': '방금 전',
      'muted': false,
      'pinned': false,
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
      'isTyping': false,
      'lastSeen': '5분 전',
      'muted': false,
      'pinned': true,
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
      'isTyping': true,
      'lastSeen': '방금 전',
      'muted': false,
      'pinned': false,
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
      'isTyping': false,
      'lastSeen': '30분 전',
      'muted': true,
      'pinned': false,
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
      'isTyping': false,
      'lastSeen': '방금 전',
      'muted': false,
      'pinned': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredChatList = _chatList;
    _startRealtimeUpdates();
  }

  @override
  void dispose() {
    _realtimeUpdateTimer?.cancel();
    super.dispose();
  }

  /// 실시간 업데이트 시작
  void _startRealtimeUpdates() {
    _realtimeUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isRealtimeUpdateEnabled && mounted) {
        _simulateNewMessages();
      }
    });
  }

  /// 새 메시지 시뮬레이션
  void _simulateNewMessages() {
    final random = DateTime.now().millisecondsSinceEpoch % _chatList.length;
    if (random < _chatList.length) {
      setState(() {
        _chatList[random]['unreadCount'] = (_chatList[random]['unreadCount'] ?? 0) + 1;
        _chatList[random]['lastMessage'] = _getRandomMessage();
        _chatList[random]['timestamp'] = '방금 전';
        _chatList[random]['isTyping'] = false;
      });
      _filterChats();
    }
  }

  /// 랜덤 메시지 생성
  String _getRandomMessage() {
    final messages = [
      '새로운 음악 아이디어가 있어요! 🎵',
      '함께 연주할까요? 🎸',
      '오늘 연습한 곡 공유해요',
      '라이브 스트림 시작할게요 🎥',
      '음악 파일 보내드릴게요 📁',
    ];
    return messages[DateTime.now().millisecondsSinceEpoch % messages.length];
  }

  /// 채팅 필터링
  void _filterChats() {
    List<Map<String, dynamic>> filtered = _chatList;

    // 검색 필터
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((chat) {
        final query = _searchQuery.toLowerCase();
        return chat['userName'].toLowerCase().contains(query) ||
               chat['lastMessage'].toLowerCase().contains(query);
      }).toList();
    }

    // 상태 필터
    switch (_selectedFilter) {
      case '온라인':
        filtered = filtered.where((chat) => chat['isOnline']).toList();
        break;
      case '미읽음':
        filtered = filtered.where((chat) => (chat['unreadCount'] ?? 0) > 0).toList();
        break;
      case '미디어':
        filtered = filtered.where((chat) => chat['lastMessageType'] == 'media').toList();
        break;
    }

    setState(() {
      _filteredChatList = filtered;
    });
  }

  /// 검색 쿼리 변경
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterChats();
  }

  /// 필터 변경
  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterChats();
  }

  /// 채팅방 옵션 표시
  void _showChatOptions(Map<String, dynamic> chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Row(
              children: [
                // 채팅 상대방 프로필 이미지 (현재 사용자인지 확인)
                chat['userName'] == AuthStateManager.instance.userName
                    ? ProfileImageManager.instance.buildProfileImage(
                        radius: 20,
                        placeholder: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.accentPink,
                          child: const Icon(Icons.person, color: AppTheme.white, size: 20),
                        ),
                      )
                    : CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.accentPink,
                        child: Text(chat['userAvatar'], style: const TextStyle(fontSize: 16)),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat['userName'],
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        chat['isOnline'] ? '온라인' : '오프라인',
                        style: const TextStyle(color: AppTheme.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 옵션들
            _buildOptionTile(
              icon: Icons.person,
              title: '프로필 보기',
              onTap: () {
                Navigator.of(context).pop();
                _showUserProfile(chat['userName']);
              },
            ),
            _buildOptionTile(
              icon: chat['pinned'] ? Icons.push_pin : Icons.push_pin_outlined,
              title: chat['pinned'] ? '고정 해제' : '고정하기',
              onTap: () {
                setState(() {
                  chat['pinned'] = !chat['pinned'];
                });
                Navigator.of(context).pop();
              },
            ),
            _buildOptionTile(
              icon: chat['muted'] ? Icons.volume_up : Icons.volume_off,
              title: chat['muted'] ? '알림 켜기' : '알림 끄기',
              onTap: () {
                setState(() {
                  chat['muted'] = !chat['muted'];
                });
                Navigator.of(context).pop();
              },
            ),
            _buildOptionTile(
              icon: Icons.delete,
              title: '채팅방 삭제',
              isDestructive: true,
              onTap: () {
                Navigator.of(context).pop();
                _deleteChat(chat);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 옵션 타일 빌드
  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppTheme.accentPink,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : AppTheme.white,
        ),
      ),
      onTap: onTap,
    );
  }

  /// 채팅방 삭제
  void _deleteChat(Map<String, dynamic> chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('채팅방 삭제', style: TextStyle(color: AppTheme.white)),
        content: Text(
          '${chat['userName']}과의 채팅방을 삭제하시겠습니까?',
          style: const TextStyle(color: AppTheme.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소', style: TextStyle(color: AppTheme.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _chatList.removeWhere((item) => item['id'] == chat['id']);
              });
              _filterChats();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('채팅방이 삭제되었습니다'),
                  backgroundColor: AppTheme.accentPink,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        title: const Text('채팅'),
        actions: [
          IconButton(
            onPressed: () => _showNewMessageModal(),
            icon: const Icon(Icons.edit),
          ),
          PopupMenuButton<String>(
            onSelected: _onFilterChanged,
            itemBuilder: (context) => _filterOptions.map((filter) {
              return PopupMenuItem(
                value: filter,
                child: Text(filter),
              );
            }).toList(),
            child: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: '채팅 검색...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                          _filterChats();
                        },
                        icon: const Icon(Icons.clear, color: AppTheme.grey),
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.secondaryBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // 필터 칩
          if (_selectedFilter != '전체')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text(_selectedFilter),
                    backgroundColor: AppTheme.accentPink,
                    labelStyle: const TextStyle(color: AppTheme.white),
                    deleteIcon: const Icon(Icons.close, color: AppTheme.white),
                    onDeleted: () => _onFilterChanged('전체'),
                  ),
                ],
              ),
            ),
          
          // 채팅 목록
          Expanded(
            child: _filteredChatList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredChatList.length,
                    itemBuilder: (context, index) {
                      final chat = _filteredChatList[index];
                      return _buildChatItem(chat);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppTheme.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? '검색 결과가 없습니다' : '채팅이 없습니다',
            style: TextStyle(
              color: AppTheme.grey.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
                ? '다른 검색어를 시도해보세요'
                : '새로운 음악인들과 연결해보세요!',
            style: TextStyle(
              color: AppTheme.grey.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 채팅방 진입
  Widget _buildChatItem(Map<String, dynamic> chat) {
    // 현재 사용자인지 확인
    final isCurrentUser = chat['userName'] == AuthStateManager.instance.userName;
    
    // 프로필 이미지 위젯 생성
    Widget profileImage;
    if (isCurrentUser) {
      try {
        profileImage = ProfileImageManager.instance.buildProfileImage(
          radius: 20,
          placeholder: CircleAvatar(
            backgroundColor: AppTheme.accentPink,
            child: const Text(
              '나',
              style: TextStyle(fontSize: 16, color: AppTheme.white),
            ),
          ),
        );
      } catch (e) {
        print('❌ 채팅 탭 프로필 이미지 생성 실패: $e');
        profileImage = CircleAvatar(
          backgroundColor: AppTheme.accentPink,
          child: const Text(
            '나',
            style: TextStyle(fontSize: 16, color: AppTheme.white),
          ),
        );
      }
    } else {
      profileImage = CircleAvatar(
        backgroundColor: AppTheme.accentPink,
        child: Text(
          chat['userAvatar'],
          style: const TextStyle(fontSize: 16),
        ),
      );
    }
    
    return ListTile(
      leading: profileImage,
      title: Row(
        children: [
          Text(
            chat['userName'],
            style: const TextStyle(
              color: AppTheme.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (chat['isOnline'])
            Container(
              margin: const EdgeInsets.only(left: 8),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      subtitle: Text(
        chat['lastMessage'],
        style: const TextStyle(color: AppTheme.grey),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            chat['timestamp'],
            style: const TextStyle(
              color: AppTheme.grey,
              fontSize: 12,
            ),
          ),
          if (chat['unreadCount'] > 0)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppTheme.accentPink,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat['unreadCount'].toString(),
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        // 로그인 상태 확인
        if (AuthStateManager.instance.requiresLogin) {
          AuthStateManager.instance.showLoginRequiredMessage(context);
          return;
        }

        setState(() {
          chat['unreadCount'] = 0;
        });
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              userName: chat['userName'],
              userAvatar: chat['userAvatar'],
            ),
          ),
        );
      },
      onLongPress: () => _showChatOptions(chat),
    );
  }

  /// 새 메시지 모달
  void _showNewMessageModal() {
    // 로그인 상태 확인
    if (AuthStateManager.instance.requiresLogin) {
      AuthStateManager.instance.showLoginRequiredMessage(context);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '새 메시지',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // 검색 필드
            TextField(
              decoration: const InputDecoration(
                labelText: '사용자 검색',
                labelStyle: TextStyle(color: AppTheme.grey),
                prefixIcon: Icon(Icons.search, color: AppTheme.grey),
                filled: true,
                fillColor: AppTheme.primaryBlack,
              ),
              style: const TextStyle(color: AppTheme.white),
            ),
            const SizedBox(height: 20),
            
            // 추천 사용자 목록
            const Text(
              '최근 연락처',
              style: TextStyle(
                color: AppTheme.grey,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // 시뮬레이션된 최근 연락처
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: AppTheme.accentPink,
                          child: Text('👤', style: const TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '사용자${index + 1}',
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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