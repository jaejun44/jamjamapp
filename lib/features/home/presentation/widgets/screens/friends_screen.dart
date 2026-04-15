import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/follow_service.dart';
import 'package:jamjamapp/core/services/supabase_service.dart';
import 'package:jamjamapp/core/services/connect_service.dart';
import '../../../../chat/presentation/screens/chat_room_screen.dart';
import 'user_profile_screen.dart';
import 'connect_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _friendRequests = [];
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFriends();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    final myId = SupabaseService.instance.currentUser?.id;
    if (myId != null) {
      final following = await FollowService.instance.getFollowing(myId);
      if (mounted) {
        setState(() {
          _friends = following.map((f) => {
            'id': f['userId'] as String,
            'name': f['nickname'] as String,
            'nickname': '@${f['username']}',
            'bio': '',
            'avatar': f['avatarUrl'] as String?,
            'isOnline': false,
            'lastSeen': '',
            'mutualFriends': 0,
            'genre': '',
          }).toList();
        });
      }
    }

    setState(() {
      _friendRequests = [
        {
          'id': '1',
          'name': 'GuitarHero',
          'nickname': '@guitarhero',
          'bio': '어쿠스틱 기타리스트입니다. 포크 음악을 연주해요.',
          'avatar': null,
          'mutualFriends': 4,
          'genre': '어쿠스틱',
          'requestTime': '2시간 전',
        },
        {
          'id': '2',
          'name': 'DrumMaster',
          'nickname': '@drummaster',
          'bio': '드러머입니다. 재즈와 락을 연주해요.',
          'avatar': null,
          'mutualFriends': 6,
          'genre': '드럼',
          'requestTime': '1일 전',
        },
      ];

      _isLoading = false;
    });

    // 매칭 목록 로드
    final matches = await ConnectService.instance.getMatches();
    if (mounted) {
      setState(() => _matches = matches);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구'),
        backgroundColor: AppTheme.secondaryBlack,
        foregroundColor: AppTheme.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentPink,
          labelColor: AppTheme.white,
          unselectedLabelColor: AppTheme.grey,
          tabs: const [
            Tab(text: '친구'),
            Tab(text: '요청'),
            Tab(text: '매칭'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentPink))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildRequestsTab(),
                _buildMatchesTab(),
              ],
            ),
    );
  }

  Widget _buildFriendsTab() {
    if (_friends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: AppTheme.grey),
            SizedBox(height: 16),
            Text(
              '친구가 없습니다',
              style: TextStyle(color: AppTheme.grey, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              '새로운 친구를 찾아보세요!',
              style: TextStyle(color: AppTheme.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return _buildFriendCard(friend);
      },
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.accentPink,
                  child: Text(
                    friend['name'][0].toUpperCase(),
                    style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
                  ),
                ),
                if (friend['isOnline'])
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: AppTheme.secondaryBlack, width: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        friend['name'],
                        style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          friend['genre'],
                          style: const TextStyle(color: AppTheme.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    friend['nickname'],
                    style: const TextStyle(color: AppTheme.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    friend['bio'],
                    style: const TextStyle(color: AppTheme.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '공통 친구 ${friend['mutualFriends']}명',
                        style: const TextStyle(color: AppTheme.grey, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        friend['isOnline'] ? '온라인' : '마지막 접속: ${friend['lastSeen']}',
                        style: TextStyle(
                          color: friend['isOnline'] ? Colors.green : AppTheme.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.grey),
              onSelected: (value) => _handleFriendAction(value, friend),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'message',
                  child: Row(
                    children: [
                      Icon(Icons.message, color: AppTheme.accentPink),
                      SizedBox(width: 8),
                      Text('메시지'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: AppTheme.accentPink),
                      SizedBox(width: 8),
                      Text('프로필 보기'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, color: Colors.red),
                      SizedBox(width: 8),
                      Text('친구 삭제', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_friendRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add, size: 64, color: AppTheme.grey),
            SizedBox(height: 16),
            Text(
              '친구 요청이 없습니다',
              style: TextStyle(color: AppTheme.grey, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              '새로운 친구 요청을 기다려보세요!',
              style: TextStyle(color: AppTheme.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _friendRequests.length,
      itemBuilder: (context, index) {
        final request = _friendRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.accentPink,
                  child: Text(
                    request['name'][0].toUpperCase(),
                    style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            request['name'],
                            style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPink,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              request['genre'],
                              style: const TextStyle(color: AppTheme.white, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        request['nickname'],
                        style: const TextStyle(color: AppTheme.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request['bio'],
                        style: const TextStyle(color: AppTheme.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '공통 친구 ${request['mutualFriends']}명',
                            style: const TextStyle(color: AppTheme.grey, fontSize: 12),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            request['requestTime'],
                            style: const TextStyle(color: AppTheme.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptFriendRequest(request),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink),
                    child: const Text('수락'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectFriendRequest(request),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.white,
                      side: const BorderSide(color: AppTheme.grey),
                    ),
                    child: const Text('거절'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesTab() {
    return Column(
      children: [
        // Connect(스와이프) 진입 버튼
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConnectScreen()),
            ),
            icon: const Icon(Icons.favorite, color: AppTheme.white),
            label: const Text('새 뮤지션 찾기',
                style: TextStyle(color: AppTheme.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPink,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        // 매칭 목록
        if (_matches.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: AppTheme.grey),
                  SizedBox(height: 16),
                  Text(
                    '아직 매칭된 뮤지션이 없습니다',
                    style: TextStyle(color: AppTheme.grey, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '위 버튼으로 뮤지션을 찾아보세요!',
                    style: TextStyle(color: AppTheme.grey),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _matches.length,
              itemBuilder: (context, index) =>
                  _buildMatchCard(_matches[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final nickname = match['nickname'] as String? ?? 'Unknown';
    final username = match['username'] as String? ?? '';
    final avatarUrl = match['avatarUrl'] as String?;

    return Card(
      color: AppTheme.secondaryBlack,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.accentPink.withValues(alpha: 0.3),
          backgroundImage:
              avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Text(
                  nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppTheme.white, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(nickname,
            style: const TextStyle(
                color: AppTheme.white, fontWeight: FontWeight.bold)),
        subtitle: username.isNotEmpty
            ? Text('@$username',
                style: const TextStyle(color: AppTheme.grey))
            : null,
        trailing: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(
                userName: nickname,
                userAvatar: avatarUrl ?? '👤',
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentPink,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('채팅', style: TextStyle(color: AppTheme.white)),
        ),
      ),
    );
  }

  void _handleFriendAction(String action, Map<String, dynamic> friend) {
    switch (action) {
      case 'message':
        _sendMessage(friend);
        break;
      case 'profile':
        _viewProfile(friend);
        break;
      case 'remove':
        _removeFriend(friend);
        break;
    }
  }

  void _sendMessage(Map<String, dynamic> friend) {
    // 실제 채팅 화면으로 이동
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          userName: friend['name'],
          userAvatar: friend['avatar'] ?? '👤',
        ),
      ),
    );
  }

  void _viewProfile(Map<String, dynamic> friend) {
    // 실제 사용자 프로필 화면으로 이동
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          username: friend['name'],
          userAvatar: friend['avatar'] ?? '👤',
          userId: friend['id'] as String?,
        ),
      ),
    );
  }

  void _removeFriend(Map<String, dynamic> friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('친구 삭제', style: TextStyle(color: AppTheme.white)),
        content: Text(
          '${friend['name']}을(를) 친구 목록에서 삭제하시겠습니까?',
          style: const TextStyle(color: AppTheme.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소', style: TextStyle(color: AppTheme.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = friend['id'] as String?;
              if (userId != null) {
                await FollowService.instance.unfollow(userId);
              }
              if (!context.mounted) return;
              setState(() {
                _friends.removeWhere((item) => item['id'] == friend['id']);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('친구가 삭제되었습니다'),
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

  void _acceptFriendRequest(Map<String, dynamic> request) {
    setState(() {
      _friendRequests.removeWhere((item) => item['id'] == request['id']);
      _friends.add({
        ...request,
        'isOnline': false,
        'lastSeen': '방금 전',
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('친구 요청이 수락되었습니다'),
        backgroundColor: AppTheme.accentPink,
      ),
    );
  }

  void _rejectFriendRequest(Map<String, dynamic> request) {
    setState(() {
      _friendRequests.removeWhere((item) => item['id'] == request['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('친구 요청이 거절되었습니다'),
        backgroundColor: AppTheme.accentPink,
      ),
    );
  }


  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('친구 검색', style: TextStyle(color: AppTheme.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: '이름 또는 닉네임',
                labelStyle: TextStyle(color: AppTheme.grey),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: AppTheme.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('검색 결과를 확인합니다'),
                    backgroundColor: AppTheme.accentPink,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink),
              child: const Text('검색'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소', style: TextStyle(color: AppTheme.grey)),
          ),
        ],
      ),
    );
  }
} 