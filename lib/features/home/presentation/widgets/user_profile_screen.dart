import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;
  final String userAvatar;

  const UserProfileScreen({
    super.key,
    required this.username,
    this.userAvatar = '👤',
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isFollowing = false;
  bool _isBlocked = false;

  // 사용자 정보 (실제로는 API에서 가져올 데이터)
  Map<String, dynamic> get _userInfo => {
    'username': widget.username,
    'displayName': widget.username,
    'avatar': widget.userAvatar,
    'bio': '음악을 사랑하는 ${widget.username}입니다 🎵',
    'followers': 1234,
    'following': 567,
    'posts': 89,
    'genre': '재즈, 팝, 락',
    'instruments': '기타, 피아노, 드럼',
    'location': '서울, 대한민국',
    'joinedDate': '2024년 1월',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 앱바
            SliverAppBar(
              backgroundColor: AppTheme.primaryBlack,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppTheme.white),
                  onPressed: () => _showOptionsModal(),
                ),
              ],
            ),
            
            // 프로필 헤더
            SliverToBoxAdapter(
              child: _buildProfileHeader(),
            ),
            
            // 통계
            SliverToBoxAdapter(
              child: _buildStats(),
            ),
            
            // 액션 버튼들
            SliverToBoxAdapter(
              child: _buildActionButtons(),
            ),
            
            // 탭바
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  labelColor: AppTheme.accentPink,
                  unselectedLabelColor: AppTheme.grey,
                  indicatorColor: AppTheme.accentPink,
                  tabs: const [
                    Tab(text: '피드'),
                    Tab(text: '음악'),
                    Tab(text: '컬렉션'),
                  ],
                ),
              ),
            ),
            
            // 탭 콘텐츠
            SliverFillRemaining(
              child: TabBarView(
                children: [
                  _buildFeedTab(),
                  _buildMusicTab(),
                  _buildCollectionTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지와 정보
          Row(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.accentPink,
                child: Text(
                  _userInfo['avatar'],
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userInfo['displayName'],
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${_userInfo['username']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _userInfo['bio'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 장르와 악기
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(_userInfo['genre']),
              _buildTag(_userInfo['instruments']),
              _buildTag(_userInfo['location']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentPink.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentPink.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.accentPink,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('피드', _userInfo['posts'].toString()),
          _buildStatItem('팔로워', _userInfo['followers'].toString()),
          _buildStatItem('팔로잉', _userInfo['following'].toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _toggleFollow(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? AppTheme.grey : AppTheme.accentPink,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(_isFollowing ? '팔로잉' : '팔로우'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _sendMessage(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.white,
                side: const BorderSide(color: AppTheme.grey),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('메시지'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text(
          '피드 탭 - 사용자의 피드들이 여기에 표시됩니다',
          style: TextStyle(color: AppTheme.grey),
        ),
      ),
    );
  }

  Widget _buildMusicTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text(
          '음악 탭 - 사용자의 음악 콘텐츠가 여기에 표시됩니다',
          style: TextStyle(color: AppTheme.grey),
        ),
      ),
    );
  }

  Widget _buildCollectionTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text(
          '컬렉션 탭 - 사용자의 컬렉션이 여기에 표시됩니다',
          style: TextStyle(color: AppTheme.grey),
        ),
      ),
    );
  }

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFollowing ? '팔로우했습니다!' : '팔로우를 취소했습니다.'),
        backgroundColor: AppTheme.accentPink,
      ),
    );
  }

  void _sendMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('메시지 기능 준비 중'),
        backgroundColor: AppTheme.accentPink,
      ),
    );
  }

  void _showOptionsModal() {
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
            ListTile(
              leading: const Icon(Icons.report, color: AppTheme.grey),
              title: const Text('신고하기', style: TextStyle(color: AppTheme.white)),
              onTap: () {
                Navigator.of(context).pop();
                _reportUser();
              },
            ),
            ListTile(
              leading: Icon(
                _isBlocked ? Icons.block : Icons.block_outlined,
                color: _isBlocked ? Colors.red : AppTheme.grey,
              ),
              title: Text(
                _isBlocked ? '차단 해제' : '차단하기',
                style: TextStyle(
                  color: _isBlocked ? Colors.red : AppTheme.white,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _toggleBlock();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _reportUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('신고 기능 준비 중'),
        backgroundColor: AppTheme.accentPink,
      ),
    );
  }

  void _toggleBlock() {
    setState(() {
      _isBlocked = !_isBlocked;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBlocked ? '사용자를 차단했습니다.' : '사용자 차단을 해제했습니다.'),
        backgroundColor: _isBlocked ? Colors.red : AppTheme.accentPink,
      ),
    );
  }
}

// SliverAppBarDelegate for TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.primaryBlack,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
} 