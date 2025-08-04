import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/auth_state_manager.dart';
import '../../../auth/presentation/widgets/login_modal.dart';
import '../../../auth/presentation/widgets/backend_test_modal.dart';
import 'profile_edit_modal.dart';
import 'social_follow_modal.dart';
import 'profile_settings_screen.dart';
import 'my_music_screen.dart';
import 'liked_content_screen.dart';
import 'bookmarks_screen.dart';
import 'friends_screen.dart';
import 'dart:typed_data'; // 웹 환경을 위해 Uint8List 사용

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // 프로필 이미지는 AuthStateManager에서 관리
  
  // 프로필 데이터 상태 변수들 추가
  String _userName = 'JamMaster';
  String _userNickname = 'jammaster';
  String _userBio = '재즈와 팝을 사랑하는 음악인입니다 🎵';
  String _userInstruments = '기타, 피아노';

  @override
  void initState() {
    super.initState();
    // AuthStateManager 상태 변화 리스너 추가
    AuthStateManager.instance.addStateChangeListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    // 리스너 제거
    AuthStateManager.instance.removeStateChangeListener(_onAuthStateChanged);
    super.dispose();
  }

  /// 인증 상태 변화 콜백
  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {
        print('🔍 프로필 탭 UI 업데이트 - isLoggedIn: ${AuthStateManager.instance.isLoggedIn}');
      });
    }
  }

  void _showLoginModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LoginModal(
        onLoginSuccess: (success) async {
          if (success) {
            print('🔍 로그인 성공 콜백 호출됨');
            
            // AuthStateManager가 이미 상태 변화를 알렸으므로 추가 작업 불필요
            if (!mounted) return;
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('로그인되었습니다!'),
                backgroundColor: AppTheme.accentPink,
              ),
            );
          }
        },
      ),
    );
  }

  void _logout() async {
    // AuthStateManager를 통해 로그아웃
    await AuthStateManager.instance.logout();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그아웃되었습니다'),
          backgroundColor: AppTheme.accentPink,
        ),
      );
    }
  }

  void _showProfileEditModal() {
    if (!AuthStateManager.instance.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 후 프로필을 편집할 수 있습니다'),
          backgroundColor: AppTheme.accentPink,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ProfileEditModal(
        // 현재 프로필 데이터를 모달에 전달
        initialName: AuthStateManager.instance.userName,
        initialNickname: AuthStateManager.instance.userNickname,
        initialBio: AuthStateManager.instance.userBio,
        initialInstruments: AuthStateManager.instance.userInstruments,
        onImageChanged: (Uint8List? imageBytes, String? imageName) async {
          print('프로필 탭에서 이미지 변경됨: $imageName'); // 디버깅
          
          // AuthStateManager를 통해 이미지 저장
          await AuthStateManager.instance.updateProfileImage(imageBytes, imageName);
          
          print('프로필 이미지 상태 업데이트됨: $imageName'); // 디버깅
        },
        onProfileSaved: (String name, String nickname, String bio, String instruments) async {
          print('프로필 데이터 저장됨: $name, $nickname, $bio, $instruments'); // 디버깅
          setState(() {
            _userName = name;
            _userNickname = nickname;
            _userBio = bio;
            _userInstruments = instruments;
          });
          
          // AuthStateManager에 프로필 데이터 저장
          await AuthStateManager.instance.saveProfileData(
            name: name,
            nickname: nickname,
            bio: bio,
            instruments: instruments,
          );
          
          print('프로필 탭에서 데이터 업데이트됨'); // 디버깅
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 프로필 헤더
            _buildProfileHeader(context),
            
            // 통계 섹션 (로그인한 상태에서만 표시)
            if (AuthStateManager.instance.isLoggedIn) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBlack,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Jam 세션', '12'),
                    _buildStatItem('팔로워', '1.2K', onTap: () => _showSocialModal('followers')),
                    _buildStatItem('팔로잉', '856', onTap: () => _showSocialModal('following')),
                  ],
                ),
              ),
            ],
            
            // 메뉴 항목들
            _buildMenuItems(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    if (!AuthStateManager.instance.isLoggedIn) {
      // 로그인하지 않은 상태
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 기본 프로필 이미지
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.grey,
              child: const Icon(Icons.person, color: AppTheme.white, size: 60),
            ),
            const SizedBox(height: 16),
            
            // 로그인 안내
            Text(
              '로그인이 필요합니다',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '프로필을 편집하려면 로그인해주세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.grey,
              ),
            ),
            const SizedBox(height: 20),
            
            // 로그인 버튼
            ElevatedButton(
              onPressed: _showLoginModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPink,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('로그인'),
            ),
          ],
        ),
      );
    }

    // 로그인한 상태
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.accentPink,
            backgroundImage: AuthStateManager.instance.profileImageBytes != null 
                ? MemoryImage(AuthStateManager.instance.profileImageBytes!) 
                : null,
            child: AuthStateManager.instance.profileImageBytes == null
                ? const Icon(Icons.person, color: AppTheme.white, size: 60)
                : null,
          ),
          const SizedBox(height: 16),
          
          // 사용자 정보
          Text(
            AuthStateManager.instance.userName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '@${AuthStateManager.instance.userNickname}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // 소개
          Text(
            AuthStateManager.instance.userBio,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 20),
          
          // 편집 버튼
          ElevatedButton(
            onPressed: _showProfileEditModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPink,
              foregroundColor: AppTheme.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('편집'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showSocialModal(String type) {
    showDialog(
      context: context,
      builder: (context) => SocialFollowModal(type: type),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 로그인된 상태에서만 표시되는 메뉴 항목들
          if (AuthStateManager.instance.isLoggedIn) ...[
            _buildMenuItem(
              icon: Icons.music_note,
              title: '내 음악',
              subtitle: '업로드한 음악들을 확인해보세요',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyMusicScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.favorite,
              title: '좋아요',
              subtitle: '좋아요한 콘텐츠를 확인해보세요',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LikedContentScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.bookmark,
              title: '북마크',
              subtitle: '저장한 콘텐츠를 확인해보세요',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BookmarksScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.people,
              title: '친구',
              subtitle: '친구 목록을 확인해보세요',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FriendsScreen(),
                  ),
                );
              },
            ),
          ],
          _buildMenuItem(
            icon: Icons.settings,
            title: '설정',
            subtitle: '앱 설정을 관리해보세요',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileSettingsScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: '도움말',
            subtitle: '앱 사용법을 확인해보세요',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.secondaryBlack,
                  title: const Text('도움말', style: TextStyle(color: AppTheme.white)),
                  content: const Text(
                    'JamJam은 음악인들을 위한 소셜 플랫폼입니다.\n\n'
                    '• 홈: 다른 음악인들의 Jam 세션을 확인하세요\n'
                    '• 검색: 새로운 음악인들을 찾아보세요\n'
                    '• Jam: 새로운 Jam 세션을 만들어보세요\n'
                    '• 채팅: 다른 음악인들과 대화해보세요\n'
                    '• 프로필: 내 정보를 관리하세요',
                    style: TextStyle(color: AppTheme.white),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('확인', style: TextStyle(color: AppTheme.accentPink)),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.build,
            title: '백엔드 테스트',
            subtitle: '백엔드 연결 상태를 확인해보세요',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const BackendTestModal(),
              );
            },
          ),
          _buildMenuItem(
            icon: AuthStateManager.instance.isLoggedIn ? Icons.logout : Icons.login,
            title: AuthStateManager.instance.isLoggedIn ? '로그아웃' : '로그인',
            subtitle: AuthStateManager.instance.isLoggedIn ? '계정에서 로그아웃합니다' : '계정에 로그인합니다',
            onTap: AuthStateManager.instance.isLoggedIn ? _logout : _showLoginModal,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.accentPink),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.grey),
        onTap: onTap,
      ),
    );
  }
} 