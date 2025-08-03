import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart';
import 'user_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _friendRequests = [];
  List<Map<String, dynamic>> _suggestedFriends = [];
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
    // 시뮬레이션된 로딩
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _friends = [
        {
          'id': '1',
          'name': 'JazzMaster',
          'nickname': '@jazzmaster',
          'bio': '재즈 피아니스트입니다. 밤의 재즈를 사랑해요.',
          'avatar': null,
          'isOnline': true,
          'lastSeen': '방금 전',
          'mutualFriends': 5,
          'genre': '재즈',
        },
        {
          'id': '2',
          'name': 'RockStar',
          'nickname': '@rockstar',
          'bio': '락 기타리스트입니다. 하드락을 연주해요.',
          'avatar': null,
          'isOnline': false,
          'lastSeen': '1시간 전',
          'mutualFriends': 3,
          'genre': '락',
        },
        {
          'id': '3',
          'name': 'PianoVirtuoso',
          'nickname': '@pianovirtuoso',
          'bio': '클래식 피아니스트입니다. 베토벤을 좋아해요.',
          'avatar': null,
          'isOnline': true,
          'lastSeen': '방금 전',
          'mutualFriends': 8,
          'genre': '클래식',
        },
        {
          'id': '4',
          'name': 'SynthWave',
          'nickname': '@synthwave',
          'bio': '일렉트로닉 음악을 만듭니다. 신스웨이브를 좋아해요.',
          'avatar': null,
          'isOnline': false,
          'lastSeen': '30분 전',
          'mutualFriends': 2,
          'genre': '일렉트로닉',
        },
      ];

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

      _suggestedFriends = [
        {
          'id': '1',
          'name': 'ViolinVirtuoso',
          'nickname': '@violinvirtuoso',
          'bio': '바이올리니스트입니다. 클래식과 재즈를 연주해요.',
          'avatar': null,
          'mutualFriends': 3,
          'genre': '클래식',
          'similarity': 85,
        },
        {
          'id': '2',
          'name': 'BassPlayer',
          'nickname': '@bassplayer',
          'bio': '베이시스트입니다. 재즈와 팝을 연주해요.',
          'avatar': null,
          'mutualFriends': 2,
          'genre': '재즈',
          'similarity': 78,
        },
        {
          'id': '3',
          'name': 'SaxophoneKing',
          'nickname': '@saxophoneking',
          'bio': '색소폰 연주자입니다. 재즈와 블루스를 사랑해요.',
          'avatar': null,
          'mutualFriends': 5,
          'genre': '재즈',
          'similarity': 92,
        },
      ];

      _isLoading = false;
    });
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
            Tab(text: '추천'),
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
                _buildSuggestionsTab(),
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

  Widget _buildSuggestionsTab() {
    if (_suggestedFriends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppTheme.grey),
            SizedBox(height: 16),
            Text(
              '추천 친구가 없습니다',
              style: TextStyle(color: AppTheme.grey, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              '나중에 다시 확인해보세요!',
              style: TextStyle(color: AppTheme.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suggestedFriends.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestedFriends[index];
        return _buildSuggestionCard(suggestion);
      },
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.accentPink,
              child: Text(
                suggestion['name'][0].toUpperCase(),
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
                        suggestion['name'],
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
                          suggestion['genre'],
                          style: const TextStyle(color: AppTheme.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    suggestion['nickname'],
                    style: const TextStyle(color: AppTheme.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suggestion['bio'],
                    style: const TextStyle(color: AppTheme.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '공통 친구 ${suggestion['mutualFriends']}명',
                        style: const TextStyle(color: AppTheme.grey, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '유사도 ${suggestion['similarity']}%',
                        style: const TextStyle(color: AppTheme.accentPink, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _sendFriendRequest(suggestion),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPink,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('친구 요청'),
            ),
          ],
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
            onPressed: () {
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

  void _sendFriendRequest(Map<String, dynamic> suggestion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${suggestion['name']}에게 친구 요청을 보냅니다'),
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