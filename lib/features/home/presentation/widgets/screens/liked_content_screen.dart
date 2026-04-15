import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'user_profile_screen.dart';
import '../../../../chat/presentation/screens/chat_room_screen.dart';

class LikedContentScreen extends StatefulWidget {
  const LikedContentScreen({super.key});

  @override
  State<LikedContentScreen> createState() => _LikedContentScreenState();
}

class _LikedContentScreenState extends State<LikedContentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _likedFeeds = [];
  List<Map<String, dynamic>> _likedMusic = [];
  List<Map<String, dynamic>> _likedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLikedContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLikedContent() async {
    // 시뮬레이션된 로딩
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _likedFeeds = [
        {
          'id': '1',
          'title': 'Jazz Night Session',
          'author': 'JazzMaster',
          'content': '밤에 연주한 재즈 세션입니다. 피아노와 색소폰의 조화가 아름다웠어요.',
          'likes': 156,
          'comments': 23,
          'timestamp': '2시간 전',
          'mediaType': 'video',
          'thumbnail': null,
        },
        {
          'id': '2',
          'title': 'Rock Band Practice',
          'author': 'RockStar',
          'content': '밴드 연습 중에 녹음한 곡입니다. 드럼과 베이스의 그루브가 좋네요!',
          'likes': 89,
          'comments': 12,
          'timestamp': '1일 전',
          'mediaType': 'audio',
          'thumbnail': null,
        },
        {
          'id': '3',
          'title': 'Classical Piano Recital',
          'author': 'PianoVirtuoso',
          'content': '베토벤 소나타 연주입니다. 클래식의 아름다움을 느껴보세요.',
          'likes': 234,
          'comments': 45,
          'timestamp': '3일 전',
          'mediaType': 'video',
          'thumbnail': null,
        },
      ];

      _likedMusic = [
        {
          'id': '1',
          'title': 'Midnight Jazz',
          'artist': 'JazzMaster',
          'genre': '재즈',
          'duration': '4:30',
          'likes': 89,
          'timestamp': '1주일 전',
        },
        {
          'id': '2',
          'title': 'Electric Dreams',
          'artist': 'SynthWave',
          'genre': '일렉트로닉',
          'duration': '6:15',
          'likes': 156,
          'timestamp': '2주일 전',
        },
        {
          'id': '3',
          'title': 'Acoustic Cover',
          'artist': 'GuitarHero',
          'genre': '어쿠스틱',
          'duration': '3:45',
          'likes': 67,
          'timestamp': '3주일 전',
        },
      ];

      _likedUsers = [
        {
          'id': '1',
          'name': 'JazzMaster',
          'nickname': '@jazzmaster',
          'bio': '재즈 피아니스트입니다. 밤의 재즈를 사랑해요.',
          'followers': 1200,
          'following': 450,
          'isOnline': true,
          'timestamp': '1주일 전',
        },
        {
          'id': '2',
          'name': 'RockStar',
          'nickname': '@rockstar',
          'bio': '락 기타리스트입니다. 하드락을 연주해요.',
          'followers': 890,
          'following': 320,
          'isOnline': false,
          'timestamp': '2주일 전',
        },
        {
          'id': '3',
          'name': 'PianoVirtuoso',
          'nickname': '@pianovirtuoso',
          'bio': '클래식 피아니스트입니다. 베토벤을 좋아해요.',
          'followers': 2100,
          'following': 180,
          'isOnline': true,
          'timestamp': '3주일 전',
        },
      ];

      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('좋아요'),
        backgroundColor: AppTheme.secondaryBlack,
        foregroundColor: AppTheme.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentPink,
          labelColor: AppTheme.white,
          unselectedLabelColor: AppTheme.grey,
          tabs: const [
            Tab(text: '피드'),
            Tab(text: '음악'),
            Tab(text: '사용자'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentPink))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLikedFeedsTab(),
                _buildLikedMusicTab(),
                _buildLikedUsersTab(),
              ],
            ),
    );
  }

  Widget _buildLikedFeedsTab() {
    if (_likedFeeds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: AppTheme.grey),
            SizedBox(height: 16),
            Text(
              '좋아요한 피드가 없습니다',
              style: TextStyle(color: AppTheme.grey, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              '마음에 드는 피드에 좋아요를 눌러보세요!',
              style: TextStyle(color: AppTheme.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _likedFeeds.length,
      itemBuilder: (context, index) {
        final feed = _likedFeeds[index];
        return _buildFeedCard(feed);
      },
    );
  }

  Widget _buildFeedCard(Map<String, dynamic> feed) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.accentPink,
                  child: Text(
                    feed['author'][0].toUpperCase(),
                    style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feed['author'],
                        style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        feed['timestamp'],
                        style: const TextStyle(color: AppTheme.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppTheme.grey),
                  onSelected: (value) => _handleFeedAction(value, feed),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'unlike',
                      child: Row(
                        children: [
                          Icon(Icons.favorite_border, color: AppTheme.accentPink),
                          SizedBox(width: 8),
                          Text('좋아요 취소'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, color: AppTheme.accentPink),
                          SizedBox(width: 8),
                          Text('공유'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              feed['title'],
              style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              feed['content'],
              style: const TextStyle(color: AppTheme.white),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.accentPink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                feed['mediaType'] == 'video' ? Icons.videocam : Icons.audiotrack,
                color: AppTheme.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.favorite, size: 16, color: AppTheme.accentPink),
                Text(' ${feed['likes']}', style: const TextStyle(color: AppTheme.grey)),
                const SizedBox(width: 16),
                Icon(Icons.comment, size: 16, color: AppTheme.grey),
                Text(' ${feed['comments']}', style: const TextStyle(color: AppTheme.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikedMusicTab() {
    if (_likedMusic.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 64, color: AppTheme.grey),
            SizedBox(height: 16),
            Text(
              '좋아요한 음악이 없습니다',
              style: TextStyle(color: AppTheme.grey, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              '마음에 드는 음악에 좋아요를 눌러보세요!',
              style: TextStyle(color: AppTheme.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _likedMusic.length,
      itemBuilder: (context, index) {
        final music = _likedMusic[index];
        return _buildMusicCard(music);
      },
    );
  }

  Widget _buildMusicCard(Map<String, dynamic> music) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.accentPink,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.music_note, color: AppTheme.white, size: 30),
        ),
        title: Text(
          music['title'],
          style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${music['artist']} • ${music['genre']} • ${music['duration']}',
              style: const TextStyle(color: AppTheme.grey),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.favorite, size: 16, color: AppTheme.accentPink),
                Text(' ${music['likes']}', style: const TextStyle(color: AppTheme.grey)),
                const SizedBox(width: 8),
                Text(
                  music['timestamp'],
                  style: const TextStyle(color: AppTheme.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.grey),
          onSelected: (value) => _handleMusicAction(value, music),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play',
              child: Row(
                children: [
                  Icon(Icons.play_arrow, color: AppTheme.accentPink),
                  SizedBox(width: 8),
                  Text('재생'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'unlike',
              child: Row(
                children: [
                  Icon(Icons.favorite_border, color: AppTheme.accentPink),
                  SizedBox(width: 8),
                  Text('좋아요 취소'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, color: AppTheme.accentPink),
                  SizedBox(width: 8),
                  Text('공유'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _playMusic(music),
      ),
    );
  }

  Widget _buildLikedUsersTab() {
    if (_likedUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 64, color: AppTheme.grey),
            SizedBox(height: 16),
            Text(
              '좋아요한 사용자가 없습니다',
              style: TextStyle(color: AppTheme.grey, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              '마음에 드는 사용자에게 좋아요를 눌러보세요!',
              style: TextStyle(color: AppTheme.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _likedUsers.length,
      itemBuilder: (context, index) {
        final user = _likedUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
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
                user['name'][0].toUpperCase(),
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
                        user['name'],
                        style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      if (user['isOnline'])
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    user['nickname'],
                    style: const TextStyle(color: AppTheme.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['bio'],
                    style: const TextStyle(color: AppTheme.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '팔로워 ${user['followers']}',
                        style: const TextStyle(color: AppTheme.grey, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '팔로잉 ${user['following']}',
                        style: const TextStyle(color: AppTheme.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.grey),
              onSelected: (value) => _handleUserAction(value, user),
              itemBuilder: (context) => [
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
                  value: 'unlike',
                  child: Row(
                    children: [
                      Icon(Icons.favorite_border, color: AppTheme.accentPink),
                      SizedBox(width: 8),
                      Text('좋아요 취소'),
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

  void _handleFeedAction(String action, Map<String, dynamic> feed) {
    switch (action) {
      case 'unlike':
        _unlikeFeed(feed);
        break;
      case 'share':
        _shareFeed(feed);
        break;
    }
  }

  void _handleMusicAction(String action, Map<String, dynamic> music) {
    switch (action) {
      case 'play':
        _playMusic(music);
        break;
      case 'unlike':
        _unlikeMusic(music);
        break;
      case 'share':
        _shareMusic(music);
        break;
    }
  }

  void _handleUserAction(String action, Map<String, dynamic> user) {
    switch (action) {
      case 'profile':
        _viewUserProfile(user);
        break;
      case 'message':
        _sendMessage(user);
        break;
      case 'unlike':
        _unlikeUser(user);
        break;
    }
  }

  void _unlikeFeed(Map<String, dynamic> feed) {
    setState(() {
      _likedFeeds.removeWhere((item) => item['id'] == feed['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('피드 좋아요가 취소되었습니다'),
        backgroundColor: AppTheme.accentPink,
      ),
    );
  }

  void _shareFeed(Map<String, dynamic> feed) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('피드가 공유되었습니다'),
        backgroundColor: AppTheme.accentPink,
      ),
    );
  }

  void _playMusic(Map<String, dynamic> music) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: Text('${music['title']} 재생', style: const TextStyle(color: AppTheme.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.accentPink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.music_note, color: AppTheme.white, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              '재생 중...',
              style: const TextStyle(color: AppTheme.white),
            ),
            const SizedBox(height: 8),
            Text(
              '${music['duration']} • ${music['genre']}',
              style: const TextStyle(color: AppTheme.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기', style: TextStyle(color: AppTheme.accentPink)),
          ),
        ],
      ),
    );
  }

  void _unlikeMusic(Map<String, dynamic> music) {
    setState(() {
      _likedMusic.removeWhere((item) => item['id'] == music['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('음악 좋아요가 취소되었습니다'),
        backgroundColor: AppTheme.accentPink,
      ),
    );
  }

  void _shareMusic(Map<String, dynamic> music) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('음악이 공유되었습니다'),
        backgroundColor: AppTheme.accentPink,
      ),
    );
  }

  void _viewUserProfile(Map<String, dynamic> user) {
    // 실제 사용자 프로필 화면으로 이동
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          username: user['name'],
          userAvatar: user['avatar'] ?? '👤',
        ),
      ),
    );
  }

  void _sendMessage(Map<String, dynamic> user) {
    // 실제 채팅 화면으로 이동
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          userName: user['name'],
          userAvatar: user['avatar'] ?? '👤',
        ),
      ),
    );
  }

  void _unlikeUser(Map<String, dynamic> user) {
    setState(() {
      _likedUsers.removeWhere((item) => item['id'] == user['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('사용자 좋아요가 취소되었습니다'),
        backgroundColor: AppTheme.accentPink,
      ),
    );
  }
} 