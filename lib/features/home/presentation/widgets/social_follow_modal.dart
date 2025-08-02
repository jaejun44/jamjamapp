import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'user_profile_screen.dart';

class SocialFollowModal extends StatefulWidget {
  final String type; // 'followers' or 'following'

  const SocialFollowModal({
    super.key,
    required this.type,
  });

  @override
  State<SocialFollowModal> createState() => _SocialFollowModalState();
}

class _SocialFollowModalState extends State<SocialFollowModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 팔로워 데이터
  final List<Map<String, dynamic>> _followers = [
    {
      'id': 1,
      'name': 'MusicLover2',
      'avatar': '🎹',
      'bio': '피아노 연주자',
      'isFollowing': true,
      'isOnline': true,
    },
    {
      'id': 2,
      'name': 'GuitarHero3',
      'avatar': '🎸',
      'bio': '기타 연주자',
      'isFollowing': false,
      'isOnline': true,
    },
    {
      'id': 3,
      'name': 'Pianist4',
      'avatar': '🎹',
      'bio': '클래식 피아니스트',
      'isFollowing': true,
      'isOnline': false,
    },
    {
      'id': 4,
      'name': 'Drummer5',
      'avatar': '🥁',
      'bio': '드러머',
      'isFollowing': false,
      'isOnline': true,
    },
    {
      'id': 5,
      'name': 'Vocalist6',
      'avatar': '🎤',
      'bio': '보컬리스트',
      'isFollowing': true,
      'isOnline': false,
    },
  ];

  // 팔로잉 데이터
  final List<Map<String, dynamic>> _following = [
    {
      'id': 1,
      'name': 'JazzMaster',
      'avatar': '🎷',
      'bio': '재즈 색소폰 연주자',
      'isFollowing': true,
      'isOnline': true,
    },
    {
      'id': 2,
      'name': 'RockStar',
      'avatar': '🎸',
      'bio': '락 기타리스트',
      'isFollowing': true,
      'isOnline': false,
    },
    {
      'id': 3,
      'name': 'ClassicalPianist',
      'avatar': '🎹',
      'bio': '클래식 피아니스트',
      'isFollowing': true,
      'isOnline': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleFollow(int userId, bool isFollowing) {
    setState(() {
      if (isFollowing) {
        // 팔로잉 목록에서 제거
        _following.removeWhere((user) => user['id'] == userId);
      } else {
        // 팔로잉 목록에 추가
        final user = _followers.firstWhere((user) => user['id'] == userId);
        _following.add({
          ...user,
          'isFollowing': true,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFollowing ? '언팔로우했습니다' : '팔로우했습니다'),
        backgroundColor: AppTheme.accentPink,
        duration: const Duration(seconds: 1),
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.secondaryBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.type == 'followers' ? '팔로워' : '팔로잉',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppTheme.white),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 탭 바
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryBlack,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.accentPink,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: AppTheme.white,
                unselectedLabelColor: AppTheme.grey,
                tabs: const [
                  Tab(text: '팔로워'),
                  Tab(text: '팔로잉'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 탭 뷰
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUserList(_followers, true),
                  _buildUserList(_following, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users, bool isFollowers) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserItem(user, isFollowers);
      },
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user, bool isFollowers) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // 아바타
          GestureDetector(
            onTap: () => _showUserProfile(user['name']),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.accentPink,
                  child: Text(
                    user['avatar'],
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                if (user['isOnline'])
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
          ),
          const SizedBox(width: 12),

          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _showUserProfile(user['name']),
                  child: Text(
                    user['name'],
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  user['bio'],
                  style: const TextStyle(
                    color: AppTheme.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // 팔로우/언팔로우 버튼
          if (isFollowers)
            ElevatedButton(
              onPressed: () => _toggleFollow(user['id'], user['isFollowing']),
              style: ElevatedButton.styleFrom(
                backgroundColor: user['isFollowing'] ? AppTheme.grey : AppTheme.accentPink,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                user['isFollowing'] ? '팔로잉' : '팔로우',
                style: const TextStyle(fontSize: 12),
              ),
            )
          else
            OutlinedButton(
              onPressed: () => _toggleFollow(user['id'], true),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentPink,
                side: const BorderSide(color: AppTheme.accentPink),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 32),
              ),
              child: const Text(
                '언팔로우',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
} 