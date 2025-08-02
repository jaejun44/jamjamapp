import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'comment_modal.dart';
import 'file_upload_modal.dart';
import 'user_profile_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // 각 피드의 좋아요/저장 상태를 관리
  final Map<int, bool> _likedFeeds = {};
  final Map<int, bool> _savedFeeds = {};

  // 실제 피드 데이터
  final List<Map<String, dynamic>> _feedData = [
    {
      'id': 1,
      'author': 'JamMaster1',
      'authorAvatar': '🎸',
      'title': '재즈 팝 퓨전 연주',
      'content': '오늘 밤에 연주한 재즈 팝 퓨전 곡입니다! 🎵 #재즈 #팝 #퓨전',
      'genre': '재즈',
      'likes': 128,
      'comments': 23,
      'shares': 5,
      'timestamp': '2시간 전',
      'mediaType': 'video',
    },
    {
      'id': 2,
      'author': 'MusicLover2',
      'authorAvatar': '🎹',
      'title': '피아노 솔로 연주',
      'content': '새로 작곡한 피아노 솔로 곡을 연주해봤어요 🎹 #피아노 #솔로 #작곡',
      'genre': '클래식',
      'likes': 95,
      'comments': 15,
      'shares': 3,
      'timestamp': '4시간 전',
      'mediaType': 'audio',
    },
    {
      'id': 3,
      'author': 'GuitarHero3',
      'authorAvatar': '🎸',
      'title': '락 기타 리프',
      'content': '오늘 연습한 락 기타 리프입니다! 🔥 #락 #기타 #리프',
      'genre': '락',
      'likes': 156,
      'comments': 31,
      'shares': 8,
      'timestamp': '6시간 전',
      'mediaType': 'video',
    },
    {
      'id': 4,
      'author': 'Pianist4',
      'authorAvatar': '🎹',
      'title': '클래식 연주회',
      'content': '어제 연주회에서 연주한 모차르트 소나타입니다 🎼 #클래식 #모차르트',
      'genre': '클래식',
      'likes': 203,
      'comments': 42,
      'shares': 12,
      'timestamp': '1일 전',
      'mediaType': 'video',
    },
    {
      'id': 5,
      'author': 'Drummer5',
      'authorAvatar': '🥁',
      'title': '드럼 솔로',
      'content': '새로 구입한 드럼으로 연주한 솔로입니다! 🥁 #드럼 #솔로',
      'genre': '록',
      'likes': 87,
      'comments': 18,
      'shares': 4,
      'timestamp': '1일 전',
      'mediaType': 'video',
    },
    {
      'id': 6,
      'author': 'Vocalist6',
      'authorAvatar': '🎤',
      'title': '보컬 커버',
      'content': '좋아하는 곡을 커버해봤어요 🎤 #보컬 #커버 #팝',
      'genre': '팝',
      'likes': 134,
      'comments': 27,
      'shares': 6,
      'timestamp': '2일 전',
      'mediaType': 'audio',
    },
  ];

  // 좋아요 상태 토글
  void _toggleLike(int index) {
    setState(() {
      _likedFeeds[index] = !(_likedFeeds[index] ?? false);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_likedFeeds[index]! ? '좋아요' : '좋아요 취소'),
        backgroundColor: AppTheme.accentPink,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // 저장 상태 토글
  void _toggleSave(int index) {
    setState(() {
      _savedFeeds[index] = !(_savedFeeds[index] ?? false);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_savedFeeds[index]! ? '저장됨' : '저장 취소'),
        backgroundColor: AppTheme.accentPink,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // 새로운 피드 추가
  void _addNewFeed(Map<String, dynamic> newFeed) {
    setState(() {
      _feedData.insert(0, newFeed);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('피드가 추가되었습니다!'),
        backgroundColor: AppTheme.accentPink,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 피드 추가 모달 표시
  void _showAddFeedModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAddFeedModal(),
    );
  }

  // 피드 추가 모달 UI
  Widget _buildAddFeedModal() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Row(
            children: [
              Text(
                '피드 추가',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppTheme.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 옵션들
          _buildAddOption(
            icon: Icons.videocam,
            title: '영상',
            subtitle: '비디오 업로드',
            onTap: () => _showFileUploadModal('video'),
          ),
          const SizedBox(height: 12),
          _buildAddOption(
            icon: Icons.music_note,
            title: '음원',
            subtitle: '오디오 파일 업로드',
            onTap: () => _showFileUploadModal('audio'),
          ),
          const SizedBox(height: 12),
          _buildAddOption(
            icon: Icons.photo,
            title: '사진',
            subtitle: '이미지 업로드',
            onTap: () => _showFileUploadModal('image'),
          ),
          const SizedBox(height: 12),
          _buildAddOption(
            icon: Icons.text_fields,
            title: '텍스트',
            subtitle: '텍스트만 작성',
            onTap: () => _showTextFeedModal(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 추가 옵션 위젯
  Widget _buildAddOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.accentPink, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.grey, size: 16),
          ],
        ),
      ),
    );
  }

  // 파일 업로드 모달 표시
  void _showFileUploadModal(String uploadType) {
    Navigator.of(context).pop(); // 피드 추가 모달 닫기
    
    showDialog(
      context: context,
      builder: (context) => FileUploadModal(
        uploadType: uploadType,
        onUploadComplete: (title, content, mediaData) {
          _addNewFeed({
            'id': DateTime.now().millisecondsSinceEpoch,
            'author': '나',
            'authorAvatar': '👤',
            'title': title,
            'content': content,
            'genre': '일반',
            'likes': 0,
            'comments': 0,
            'shares': 0,
            'timestamp': '방금 전',
            'mediaType': uploadType,
            'mediaData': mediaData,
          });
        },
      ),
    );
  }

  // 텍스트 피드 모달 표시
  void _showTextFeedModal() {
    Navigator.of(context).pop(); // 피드 추가 모달 닫기
    
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: Text(
          '텍스트 피드 작성',
          style: TextStyle(color: AppTheme.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: TextStyle(color: AppTheme.white),
              decoration: InputDecoration(
                labelText: '제목',
                labelStyle: TextStyle(color: AppTheme.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              style: TextStyle(color: AppTheme.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '내용',
                labelStyle: TextStyle(color: AppTheme.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.grey),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소', style: TextStyle(color: AppTheme.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                _addNewFeed({
                  'id': DateTime.now().millisecondsSinceEpoch,
                  'author': '나',
                  'authorAvatar': '👤',
                  'title': titleController.text,
                  'content': contentController.text,
                  'genre': '일반',
                  'likes': 0,
                  'comments': 0,
                  'shares': 0,
                  'timestamp': '방금 전',
                  'mediaType': 'text',
                });
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPink,
              foregroundColor: AppTheme.white,
            ),
            child: Text('업로드'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(context),
            
            // 피드 목록
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _feedData.length,
                itemBuilder: (context, index) {
                  final feed = _feedData[index];
                  return _buildFeedCard(feed, index);
                },
              ),
            ),
          ],
        ),
      ),
      // 피드 추가 플로팅 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddFeedModal();
        },
        backgroundColor: AppTheme.accentPink,
        child: const Icon(
          Icons.add,
          color: AppTheme.white,
          size: 30,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            'JamJam',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.white),
            onPressed: () {
              // TODO: 검색
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.white),
            onPressed: () {
              // TODO: 알림
            },
          ),
        ],
      ),
    );
  }

  // 피드 카드 빌드
  Widget _buildFeedCard(Map<String, dynamic> feed, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 피드 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 작성자 아이콘 (클릭 가능)
                GestureDetector(
                  onTap: () => _showUserProfile(feed['author']),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.accentPink,
                    child: Text(
                      feed['authorAvatar'],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 작성자 이름 (클릭 가능)
                      GestureDetector(
                        onTap: () => _showUserProfile(feed['author']),
                        child: Text(
                          feed['author'],
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        feed['timestamp'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppTheme.grey),
                  onPressed: () {
                    // TODO: 피드 옵션 메뉴
                  },
                ),
              ],
            ),
          ),
          
          // 피드 제목
          if (feed['title'] != null && feed['title'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                feed['title'],
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          // 피드 내용
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              feed['content'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.white,
              ),
            ),
          ),
          
          // 미디어 콘텐츠
          if (feed['mediaType'] != 'text')
            _buildMediaContent(feed),
          
          // 액션 버튼들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildActionButton(
                  icon: _likedFeeds[index] == true ? Icons.favorite : Icons.favorite_border,
                  label: '${feed['likes']}',
                  isActive: _likedFeeds[index] == true,
                  onTap: () => _toggleLike(index),
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: '${feed['comments']}',
                  isActive: false,
                  onTap: () => _showCommentModal(feed),
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.share,
                  label: '${feed['shares']}',
                  isActive: false,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('공유 기능 준비 중'),
                        backgroundColor: AppTheme.accentPink,
                      ),
                    );
                  },
                ),
                const Spacer(),
                _buildActionButton(
                  icon: _savedFeeds[index] == true ? Icons.bookmark : Icons.bookmark_border,
                  label: '저장',
                  isActive: _savedFeeds[index] == true,
                  onTap: () => _toggleSave(index),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 미디어 콘텐츠 빌드
  Widget _buildMediaContent(Map<String, dynamic> feed) {
    final mediaType = feed['mediaType'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mediaType == 'video' ? Icons.videocam :
              mediaType == 'audio' ? Icons.music_note :
              mediaType == 'image' ? Icons.photo :
              Icons.music_note,
              size: 48,
              color: AppTheme.accentPink,
            ),
            const SizedBox(height: 8),
            Text(
              mediaType == 'video' ? '비디오 콘텐츠' :
              mediaType == 'audio' ? '오디오 콘텐츠' :
              mediaType == 'image' ? '이미지 콘텐츠' :
              '미디어 콘텐츠',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.grey,
              ),
            ),
            if (feed['mediaData'] != null)
              Text(
                '미디어 데이터 포함',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.accentPink,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 액션 버튼 빌드
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppTheme.accentPink : AppTheme.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive ? AppTheme.accentPink : AppTheme.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 댓글 모달 표시
  void _showCommentModal(Map<String, dynamic> feed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.secondaryBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CommentModal(feedIndex: _feedData.indexOf(feed)),
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