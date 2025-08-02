import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'comment_modal.dart';
import 'file_upload_modal.dart';
import 'user_profile_screen.dart';
import 'media_player_widget.dart';
import 'share_modal.dart';
import 'feed_edit_modal.dart';
import 'dart:async';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // 각 피드의 좋아요/저장 상태를 관리
  final Map<int, bool> _likedFeeds = {};
  final Map<int, bool> _savedFeeds = {};
  
  // 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();
  
  // 페이지네이션
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  static const int _itemsPerPage = 10;
  
  // 새로고침 상태
  bool _isRefreshing = false;
  
  // 실시간 업데이트 상태
  Timer? _realtimeUpdateTimer;
  bool _isRealtimeUpdateEnabled = true;
  DateTime _lastUpdateTime = DateTime.now();
  
  // 팔로우 상태 관리
  final Set<String> _followedUsers = {};
  
  // 필터 상태
  String _selectedGenre = '전체';
  String _selectedMediaType = '전체';
  String _searchQuery = '';
  
  // 필터 옵션
  final List<String> _genres = ['전체', '재즈', '팝', '락', '클래식', '일렉트로닉'];
  final List<String> _mediaTypes = ['전체', '비디오', '오디오', '이미지', '텍스트'];

  // 실제 피드 데이터 (확장된 버전)
  List<Map<String, dynamic>> _allFeedData = [
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
      'tags': ['재즈', '팝', '퓨전', '기타'],
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
      'tags': ['클래식', '피아노', '솔로', '작곡'],
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
      'tags': ['락', '기타', '리프', '연습'],
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
      'tags': ['클래식', '모차르트', '연주회', '피아노'],
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
      'tags': ['록', '드럼', '솔로', '새드럼'],
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
      'tags': ['팝', '보컬', '커버', '노래'],
    },
    {
      'id': 7,
      'author': 'Producer7',
      'authorAvatar': '🎧',
      'title': '일렉트로닉 비트',
      'content': '새로 만든 일렉트로닉 비트입니다! 🎧 #일렉트로닉 #비트 #프로듀싱',
      'genre': '일렉트로닉',
      'likes': 178,
      'comments': 35,
      'shares': 9,
      'timestamp': '3일 전',
      'mediaType': 'audio',
      'tags': ['일렉트로닉', '비트', '프로듀싱', 'EDM'],
    },
    {
      'id': 8,
      'author': 'Composer8',
      'authorAvatar': '🎼',
      'title': '오케스트라 작곡',
      'content': '새로 작곡한 오케스트라 곡입니다 🎼 #작곡 #오케스트라 #클래식',
      'genre': '클래식',
      'likes': 245,
      'comments': 48,
      'shares': 15,
      'timestamp': '4일 전',
      'mediaType': 'audio',
      'tags': ['클래식', '작곡', '오케스트라', '교향곡'],
    },
  ];

  // 현재 표시할 피드 데이터
  List<Map<String, dynamic>> _feedData = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupScrollListener();
    _startRealtimeUpdates();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _realtimeUpdateTimer?.cancel();
    super.dispose();
  }

  /// 초기 데이터 로드
  void _loadInitialData() {
    _feedData = _allFeedData.take(_itemsPerPage).toList();
    _currentPage = 1;
    _hasMoreData = _allFeedData.length > _itemsPerPage;
  }

  /// 스크롤 리스너 설정
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _loadMoreData();
      }
    });
  }

  /// 더 많은 데이터 로드
  void _loadMoreData() {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    // 시뮬레이션된 로딩
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final startIndex = _currentPage * _itemsPerPage;
        final endIndex = startIndex + _itemsPerPage;
        
        if (startIndex < _allFeedData.length) {
          final newItems = _allFeedData.skip(startIndex).take(_itemsPerPage).toList();
          setState(() {
            _feedData.addAll(newItems);
            _currentPage++;
            _hasMoreData = endIndex < _allFeedData.length;
            _isLoadingMore = false;
          });
        } else {
          setState(() {
            _hasMoreData = false;
            _isLoadingMore = false;
          });
        }
      }
    });
  }

  /// 피드 새로고침
  Future<void> _refreshFeeds() async {
    setState(() {
      _isRefreshing = true;
    });

    // 시뮬레이션된 새로고침
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
        _loadInitialData();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('새로운 피드가 로드되었습니다!'),
          backgroundColor: AppTheme.accentPink,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 피드 필터링
  void _filterFeeds() {
    List<Map<String, dynamic>> filtered = _allFeedData;

    // 장르 필터
    if (_selectedGenre != '전체') {
      filtered = filtered.where((feed) => feed['genre'] == _selectedGenre).toList();
    }

    // 미디어 타입 필터
    if (_selectedMediaType != '전체') {
      filtered = filtered.where((feed) => feed['mediaType'] == _selectedMediaType.toLowerCase()).toList();
    }

    // 검색 필터
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((feed) {
        final query = _searchQuery.toLowerCase();
        return feed['title'].toLowerCase().contains(query) ||
               feed['content'].toLowerCase().contains(query) ||
               feed['author'].toLowerCase().contains(query) ||
               feed['tags'].any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    setState(() {
      _feedData = filtered.take(_itemsPerPage).toList();
      _currentPage = 1;
      _hasMoreData = filtered.length > _itemsPerPage;
    });
  }

  /// 필터 모달 표시
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterModal(),
    );
  }

  /// 필터 모달 UI
  Widget _buildFilterModal() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '피드 필터',
                style: TextStyle(
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
          const SizedBox(height: 24),
          
          // 검색바
          TextField(
            onChanged: (value) {
              _searchQuery = value;
              _filterFeeds();
            },
            style: const TextStyle(color: AppTheme.white),
            decoration: InputDecoration(
              hintText: '피드 검색...',
              hintStyle: const TextStyle(color: AppTheme.grey),
              prefixIcon: const Icon(Icons.search, color: AppTheme.grey),
              filled: true,
              fillColor: AppTheme.primaryBlack,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 장르 필터
          _buildFilterSection('장르', _genres, _selectedGenre, (value) {
            setState(() {
              _selectedGenre = value;
            });
            _filterFeeds();
          }),
          const SizedBox(height: 16),
          
          // 미디어 타입 필터
          _buildFilterSection('미디어 타입', _mediaTypes, _selectedMediaType, (value) {
            setState(() {
              _selectedMediaType = value;
            });
            _filterFeeds();
          }),
          const SizedBox(height: 24),
          
          // 필터 초기화 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedGenre = '전체';
                  _selectedMediaType = '전체';
                  _searchQuery = '';
                });
                _filterFeeds();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPink,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('필터 초기화'),
            ),
          ),
        ],
      ),
    );
  }

  /// 실시간 업데이트 시작
  void _startRealtimeUpdates() {
    _realtimeUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isRealtimeUpdateEnabled && mounted) {
        _checkForNewFeeds();
      }
    });
  }

  /// 새 피드 확인
  void _checkForNewFeeds() {
    // 시뮬레이션된 새 피드 생성
    final now = DateTime.now();
    if (now.difference(_lastUpdateTime).inMinutes >= 1) {
      _addSimulatedNewFeed();
      _lastUpdateTime = now;
    }
  }

  /// 시뮬레이션된 새 피드 추가
  void _addSimulatedNewFeed() {
    final newFeed = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'author': 'NewArtist${DateTime.now().second}',
      'authorAvatar': '🎵',
      'title': '새로운 음악 ${DateTime.now().second}',
      'content': '방금 전에 업로드된 새로운 음악입니다! 🎵 #새음악 #실시간',
      'genre': '팝',
      'likes': 0,
      'comments': 0,
      'shares': 0,
      'timestamp': '방금 전',
      'mediaType': 'audio',
      'tags': ['새음악', '실시간', '팝'],
    };

    setState(() {
      _allFeedData.insert(0, newFeed);
      if (_feedData.isNotEmpty) {
        _feedData.insert(0, newFeed);
      }
    });

    // 새 피드 알림
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.new_releases, color: AppTheme.white),
              const SizedBox(width: 8),
              const Text('새로운 피드가 추가되었습니다!'),
            ],
          ),
          backgroundColor: AppTheme.accentPink,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: '보기',
            textColor: AppTheme.white,
            onPressed: () {
              // 스크롤을 맨 위로 이동
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
          ),
        ),
      );
    }
  }

  /// 팔로우 토글
  void _toggleFollow(String username) {
    setState(() {
      if (_followedUsers.contains(username)) {
        _followedUsers.remove(username);
      } else {
        _followedUsers.add(username);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_followedUsers.contains(username) ? '$username을 팔로우했습니다!' : '$username을 언팔로우했습니다.'),
        backgroundColor: AppTheme.accentPink,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 실시간 업데이트 토글
  void _toggleRealtimeUpdates() {
    setState(() {
      _isRealtimeUpdateEnabled = !_isRealtimeUpdateEnabled;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isRealtimeUpdateEnabled ? '실시간 업데이트 활성화' : '실시간 업데이트 비활성화'),
        backgroundColor: AppTheme.accentPink,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 필터 섹션 빌드
  Widget _buildFilterSection(String title, List<String> options, String selected, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) => FilterChip(
            label: Text(option),
            selected: selected == option,
            onSelected: (selected) => onChanged(option),
            backgroundColor: AppTheme.primaryBlack,
            selectedColor: AppTheme.accentPink,
            labelStyle: TextStyle(
              color: selected == option ? AppTheme.white : AppTheme.grey,
            ),
            checkmarkColor: AppTheme.white,
          )).toList(),
        ),
      ],
    );
  }

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
            
            // 피드 목록 (새로고침 + 무한 스크롤)
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshFeeds,
                color: AppTheme.accentPink,
                backgroundColor: AppTheme.secondaryBlack,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _feedData.length + (_hasMoreData ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _feedData.length) {
                      // 로딩 인디케이터
                      return _buildLoadingIndicator();
                    }
                    final feed = _feedData[index];
                    return _buildFeedCard(feed, index);
                  },
                ),
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

  /// 로딩 인디케이터 빌드
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              color: AppTheme.accentPink,
            ),
            SizedBox(height: 8),
            Text(
              '더 많은 피드를 로드하는 중...',
              style: TextStyle(
                color: AppTheme.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
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
          // 실시간 업데이트 토글 버튼
          IconButton(
            icon: Icon(
              _isRealtimeUpdateEnabled ? Icons.sync : Icons.sync_disabled,
              color: _isRealtimeUpdateEnabled ? AppTheme.accentPink : AppTheme.grey,
            ),
            onPressed: _toggleRealtimeUpdates,
            tooltip: '실시간 업데이트',
          ),
          // 필터 버튼
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppTheme.white),
            onPressed: _showFilterModal,
            tooltip: '피드 필터',
          ),
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
                // 팔로우 버튼
                if (feed['author'] != '나') // 자신의 피드는 팔로우 버튼 숨김
                  GestureDetector(
                    onTap: () => _toggleFollow(feed['author']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _followedUsers.contains(feed['author']) 
                          ? AppTheme.grey.withValues(alpha: 0.3)
                          : AppTheme.accentPink,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _followedUsers.contains(feed['author']) 
                            ? AppTheme.grey 
                            : AppTheme.accentPink,
                        ),
                      ),
                      child: Text(
                        _followedUsers.contains(feed['author']) ? '팔로잉' : '팔로우',
                        style: TextStyle(
                          color: _followedUsers.contains(feed['author']) 
                            ? AppTheme.grey 
                            : AppTheme.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppTheme.grey),
                  onPressed: () => _showFeedOptions(feed),
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
                  onTap: () => _showShareModal(feed),
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
      child: MediaPlayerWidget(
        mediaType: mediaType,
        mediaUrl: feed['mediaUrl'],
        mediaData: feed['mediaData'],
        title: feed['title'] ?? '미디어 콘텐츠',
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

  /// 피드 옵션 모달 표시
  void _showFeedOptions(Map<String, dynamic> feed) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FeedEditModal(
        feed: feed,
        onFeedUpdated: _updateFeed,
        onFeedDeleted: _deleteFeed,
      ),
    );
  }

  /// 피드 업데이트
  void _updateFeed(Map<String, dynamic> updatedFeed) {
    setState(() {
      final index = _feedData.indexWhere((feed) => feed['id'] == updatedFeed['id']);
      if (index != -1) {
        _feedData[index] = updatedFeed;
      }
      
      final allIndex = _allFeedData.indexWhere((feed) => feed['id'] == updatedFeed['id']);
      if (allIndex != -1) {
        _allFeedData[allIndex] = updatedFeed;
      }
    });
  }

  /// 피드 삭제
  void _deleteFeed(int feedId) {
    setState(() {
      _feedData.removeWhere((feed) => feed['id'] == feedId);
      _allFeedData.removeWhere((feed) => feed['id'] == feedId);
    });
  }

  /// 공유 모달 표시
  void _showShareModal(Map<String, dynamic> feed) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ShareModal(feed: feed),
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