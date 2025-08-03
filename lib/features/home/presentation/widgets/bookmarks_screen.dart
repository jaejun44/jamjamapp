import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'user_profile_screen.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _bookmarkedFeeds = [];
  List<Map<String, dynamic>> _bookmarkedMusic = [];
  List<Map<String, dynamic>> _bookmarkedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookmarks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    // 시뮬레이션된 로딩
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _bookmarkedFeeds = [
        {
          'id': '1',
          'title': 'Jazz Improvisation Tips',
          'author': 'JazzMaster',
          'content': '재즈 즉흥연주를 위한 팁들을 정리했습니다. 스케일과 코드 진행에 대해 설명합니다.',
          'likes': 234,
          'comments': 45,
          'timestamp': '1일 전',
          'mediaType': 'video',
          'thumbnail': null,
          'category': '교육',
        },
        {
          'id': '2',
          'title': 'Rock Guitar Techniques',
          'author': 'RockStar',
          'content': '락 기타 테크닉을 소개합니다. 파워코드와 리프 연주법을 배워보세요.',
          'likes': 189,
          'comments': 32,
          'timestamp': '3일 전',
          'mediaType': 'video',
          'thumbnail': null,
          'category': '교육',
        },
        {
          'id': '3',
          'title': 'Classical Music History',
          'author': 'PianoVirtuoso',
          'content': '클래식 음악의 역사와 발전 과정에 대해 알아봅니다.',
          'likes': 156,
          'comments': 28,
          'timestamp': '1주일 전',
          'mediaType': 'audio',
          'thumbnail': null,
          'category': '역사',
        },
      ];

      _bookmarkedMusic = [
        {
          'id': '1',
          'title': 'Moonlight Sonata',
          'artist': 'PianoVirtuoso',
          'genre': '클래식',
          'duration': '15:30',
          'likes': 456,
          'timestamp': '2주일 전',
          'category': '피아노',
        },
        {
          'id': '2',
          'title': 'Blues in the Night',
          'artist': 'JazzMaster',
          'genre': '재즈',
          'duration': '8:45',
          'likes': 234,
          'timestamp': '3주일 전',
          'category': '재즈',
        },
        {
          'id': '3',
          'title': 'Electric Storm',
          'artist': 'RockStar',
          'genre': '락',
          'duration': '6:20',
          'likes': 189,
          'timestamp': '1개월 전',
          'category': '락',
        },
      ];

      _bookmarkedUsers = [
        {
          'id': '1',
          'name': 'JazzMaster',
          'nickname': '@jazzmaster',
          'bio': '재즈 피아니스트입니다. 밤의 재즈를 사랑해요.',
          'followers': 1200,
          'following': 450,
          'isOnline': true,
          'timestamp': '1주일 전',
          'category': '재즈',
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
          'category': '락',
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
          'category': '클래식',
        },
      ];

      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('북마크'),
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
                _buildBookmarkedFeedsTab(),
                _buildBookmarkedMusicTab(),
                _buildBookmarkedUsersTab(),
              ],
            ),
    );
  }

  Widget _buildBookmarkedFeedsTab() {
    if (_bookmarkedFeeds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: AppTheme.grey),
            SizedBox(height: 16),
            Text(
              '북마크한 피드가 없습니다',
              style: TextStyle(color: AppTheme.grey, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              '나중에 보고 싶은 피드를 북마크해보세요!',
              style: TextStyle(color: AppTheme.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookmarkedFeeds.length,
      itemBuilder: (context, index) {
        final feed = _bookmarkedFeeds[index];
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    feed['category'],
                    style: const TextStyle(color: AppTheme.white, fontSize: 12),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppTheme.grey),
                  onSelected: (value) => _handleFeedAction(value, feed),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.bookmark_border, color: AppTheme.accentPink),
                          SizedBox(width: 8),
                          Text('북마크 제거'),
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
                Icon(Icons.favorite, size: 16, color: AppTheme.grey),
                Text(' ${feed['likes']}', style: const TextStyle(color: AppTheme.grey)),
                const SizedBox(width: 16),
                Icon(Icons.comment, size: 16, color: AppTheme.grey),
                Text(' ${feed['comments']}', style: const TextStyle(color: AppTheme.grey)),
                const Spacer(),
                Icon(Icons.bookmark, size: 16, color: AppTheme.accentPink),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkedMusicTab() {
    if (_bookmarkedMusic.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 64, color: AppTheme.grey),
            SizedBox(height: 16),
            Text(
              '북마크한 음악이 없습니다',
              style: TextStyle(color: AppTheme.grey, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              '나중에 듣고 싶은 음악을 북마크해보세요!',
              style: TextStyle(color: AppTheme.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookmarkedMusic.length,
      itemBuilder: (context, index) {
        final music = _bookmarkedMusic[index];
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
                Icon(Icons.favorite, size: 16, color: AppTheme.grey),
                Text(' ${music['likes']}', style: const TextStyle(color: AppTheme.grey)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    music['category'],
                    style: const TextStyle(color: AppTheme.white, fontSize: 10),
                  ),
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
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.bookmark_border, color: AppTheme.accentPink),
                  SizedBox(width: 8),
                  Text('북마크 제거'),
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

  Widget _buildBookmarkedUsersTab() {
    if (_bookmarkedUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 64, color: AppTheme.grey),
            SizedBox(height: 16),
            Text(
              '북마크한 사용자가 없습니다',
              style: TextStyle(color: AppTheme.grey, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              '나중에 확인하고 싶은 사용자를 북마크해보세요!',
              style: TextStyle(color: AppTheme.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookmarkedUsers.length,
      itemBuilder: (context, index) {
        final user = _bookmarkedUsers[index];
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
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user['category'],
                          style: const TextStyle(color: AppTheme.white, fontSize: 10),
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
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.bookmark_border, color: AppTheme.accentPink),
                      SizedBox(width: 8),
                      Text('북마크 제거'),
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
      case 'remove':
        _removeBookmarkFeed(feed);
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
      case 'remove':
        _removeBookmarkMusic(music);
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
      case 'remove':
        _removeBookmarkUser(user);
        break;
    }
  }

  void _removeBookmarkFeed(Map<String, dynamic> feed) {
    setState(() {
      _bookmarkedFeeds.removeWhere((item) => item['id'] == feed['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('피드 북마크가 제거되었습니다'),
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

  void _removeBookmarkMusic(Map<String, dynamic> music) {
    setState(() {
      _bookmarkedMusic.removeWhere((item) => item['id'] == music['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('음악 북마크가 제거되었습니다'),
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

  void _removeBookmarkUser(Map<String, dynamic> user) {
    setState(() {
      _bookmarkedUsers.removeWhere((item) => item['id'] == user['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('사용자 북마크가 제거되었습니다'),
        backgroundColor: AppTheme.accentPink,
      ),
    );
  }
} 