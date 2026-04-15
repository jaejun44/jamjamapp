import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/app_state_manager.dart';
import 'package:jamjamapp/core/services/auth_state_manager.dart';
import 'package:jamjamapp/core/services/comment_service.dart';
import 'package:jamjamapp/core/services/counter_service.dart';
import 'package:jamjamapp/core/services/like_service.dart';
import 'package:jamjamapp/core/services/feed_service.dart';
import 'package:jamjamapp/core/services/follow_service.dart';
import 'package:jamjamapp/core/services/supabase_service.dart';
import '../modals/comment_modal.dart';
import '../modals/file_upload_modal.dart';
import '../screens/user_profile_screen.dart';
import '../shared/feed_card.dart';
import '../modals/share_modal.dart';
import '../modals/feed_edit_modal.dart';
import '../screens/trending_feeds_screen.dart';
import '../screens/notifications_screen.dart';
import 'package:jamjamapp/core/services/notification_service.dart';
import 'dart:async';
import 'dart:typed_data';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // AppStateManager를 통해 상태 관리
  final AppStateManager _appStateManager = AppStateManager.instance;
  
  // 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();
  
  // 페이지네이션
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  static const int _itemsPerPage = 10;
  
  // 실시간 업데이트 상태
  Timer? _realtimeUpdateTimer;
  
  // 필터 옵션
  final List<String> _genres = ['전체', '재즈', '팝', '락', '클래식', '일렉트로닉'];
  final List<String> _mediaTypes = ['전체', '비디오', '오디오', '이미지', '텍스트'];

  // 기본값 상수 정의 - 수정: Map은 생성자, List는 리터럴
  static final Map<int, bool> _emptyLikedFeeds = <int, bool>{}; // 🔧 리터럴 대신 생성자 사용
  static final Map<int, bool> _emptySavedFeeds = <int, bool>{}; // 🔧 리터럴 대신 생성자 사용
  static final List<String> _emptyFollowedUsers = <String>[]; // 🔧 List 리터럴은 안전함

  // AppStateManager에서 상태를 가져오는 getter 메서드들 - ChatGPT-4o 권장
  Map<int, bool> get _likedFeeds {
    final rawData = _appStateManager.homeState['likedFeeds'];
    if (rawData is Map) {
      try {
        // JSON에서 복원된 Map<String, dynamic>을 Map<int, bool>로 변환
        final Map<int, bool> convertedMap = <int, bool>{};
        rawData.forEach((key, value) {
          final intKey = key is String ? int.tryParse(key) ?? 0 : key as int;
          final boolValue = value is bool ? value : false;
          convertedMap[intKey] = boolValue;
        });
        return convertedMap;
      } catch (e) {
        return _emptyLikedFeeds;
      }
    }
    return _emptyLikedFeeds;
  }
  
  Map<int, bool> get _savedFeeds {
    final rawData = _appStateManager.homeState['savedFeeds'];
    if (rawData is Map) {
      try {
        // JSON에서 복원된 Map<String, dynamic>을 Map<int, bool>로 변환
        final Map<int, bool> convertedMap = <int, bool>{};
        rawData.forEach((key, value) {
          final intKey = key is String ? int.tryParse(key) ?? 0 : key as int;
          final boolValue = value is bool ? value : false;
          convertedMap[intKey] = boolValue;
        });
        return convertedMap;
      } catch (e) {
        return _emptySavedFeeds;
      }
    }
    return _emptySavedFeeds;
  }
  List<String> get _followedUsers {
    final rawData = _appStateManager.homeState['followedUsers'];
    if (rawData is List) {
      try {
        return rawData.cast<String>();
      } catch (e) {
        return _emptyFollowedUsers;
      }
    }
    return _emptyFollowedUsers;
  }
  bool get _isPersonalizedMode => _appStateManager.homeState['isPersonalizedMode'] ?? true;
  bool get _isOfflineMode => _appStateManager.homeState['isOfflineMode'] ?? false;
  bool get _isRealtimeUpdateEnabled => _appStateManager.homeState['isRealtimeUpdateEnabled'] ?? true;
  String get _selectedGenre => _appStateManager.homeState['selectedGenre'] ?? '전체';
  String get _selectedMediaType => _appStateManager.homeState['selectedMediaType'] ?? '전체';
  String get _searchQuery => _appStateManager.homeState['searchQuery'] ?? '';

  // AppStateManager를 통해 상태를 업데이트하는 메서드들
  Future<void> _updateSearchQuery(String value) async {
    await _appStateManager.updateValue('home', 'searchQuery', value);
  }

  Future<void> _updateSelectedGenre(String value) async {
    await _appStateManager.updateValue('home', 'selectedGenre', value);
  }

  Future<void> _updateSelectedMediaType(String value) async {
    await _appStateManager.updateValue('home', 'selectedMediaType', value);
  }

  Future<void> _updateRealtimeUpdateEnabled(bool value) async {
    await _appStateManager.updateValue('home', 'isRealtimeUpdateEnabled', value);
  }

  Future<void> _updatePersonalizedMode(bool value) async {
    await _appStateManager.updateValue('home', 'isPersonalizedMode', value);
  }

  Future<void> _updateOfflineMode(bool value) async {
    await _appStateManager.updateValue('home', 'isOfflineMode', value);
  }

  // 피드 모드: '전체' | '팔로잉'
  String _feedMode = '전체';

  // 읽지 않은 알림 수
  int _unreadNotificationCount = 0;

  // 사용자가 생성한 실제 피드 데이터만 저장
  final List<Map<String, dynamic>> _allFeedData = [];

  // 현재 표시할 피드 데이터
  List<Map<String, dynamic>> _feedData = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupScrollListener();
    _startRealtimeUpdates();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationService.instance.getUnreadCount();
    if (!mounted) return;
    setState(() => _unreadNotificationCount = count);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _realtimeUpdateTimer?.cancel();
    super.dispose();
  }

  /// 초기 데이터 로드 (CounterService 연동) - 안전한 타입 변환
  void _loadInitialData() {
    // AppStateManager에서 저장된 피드 데이터 로드 - 안전한 타입 변환
    final rawFeedData = AppStateManager.instance.getState('home')['feedData'];
    List<Map<String, dynamic>>? savedFeedData;

    if (rawFeedData is List) {
      // List<dynamic>을 List<Map<String, dynamic>>로 안전하게 변환
      try {
        savedFeedData = rawFeedData.cast<Map<String, dynamic>>();
      } catch (e) {
        savedFeedData = null;
      }
    }

    if (savedFeedData != null && savedFeedData.isNotEmpty) {
      _feedData = savedFeedData;
      _hasMoreData = _allFeedData.length > _feedData.length;
    } else {
      _feedData = _allFeedData.take(_itemsPerPage).toList();
      _hasMoreData = _allFeedData.length > _itemsPerPage;
      // AppStateManager에 저장
      AppStateManager.instance.updateValue('home', 'feedData', _feedData);
    }

    // CounterService에서 실제 카운트 동기화
    _syncCountsWithCounterService();

    // 사용자 좋아요 상태 복원
    _syncUserLikeStates();

    // Supabase에서 최신 피드 비동기 로드
    _fetchFeedsFromSupabase();
  }

  /// Supabase에서 피드 목록 로드 후 상태 업데이트
  Future<void> _fetchFeedsFromSupabase() async {
    try {
      final feeds = await FeedService.instance.fetchFeeds(limit: _itemsPerPage);
      if (!mounted || feeds.isEmpty) return;
      for (final feed in feeds) {
        await CounterService.instance.initializeFeedCounts(
          feed['id'] as int,
          likes: feed['likes'] as int? ?? 0,
          comments: feed['comments'] as int? ?? 0,
          shares: 0,
        );
      }
      setState(() {
        _allFeedData
          ..clear()
          ..addAll(feeds);
        _feedData = List<Map<String, dynamic>>.from(feeds);
        _hasMoreData = feeds.length >= _itemsPerPage;
      });
      AppStateManager.instance.updateValue('home', 'feedData', _feedData);
      _syncCountsWithCounterService();
      _syncUserLikeStates();
    } catch (_) {}
  }

  /// 팔로잉 유저의 피드만 로드
  Future<void> _fetchFollowingFeeds() async {
    try {
      final myId = SupabaseService.instance.currentUser?.id;
      if (myId == null) return;

      final following = await FollowService.instance.getFollowing(myId);
      final followingIds = following
          .map((f) => f['userId'] as String?)
          .whereType<String>()
          .toSet();

      if (!mounted) return;

      if (followingIds.isEmpty) {
        setState(() {
          _allFeedData.clear();
          _feedData = [];
          _hasMoreData = false;
        });
        return;
      }

      final feeds = await FeedService.instance.fetchFeeds(limit: 50);
      if (!mounted) return;

      final filtered = feeds
          .where((f) => followingIds.contains(f['authorId'] as String?))
          .toList();

      for (final feed in filtered) {
        await CounterService.instance.initializeFeedCounts(
          feed['id'] as int,
          likes: feed['likes'] as int? ?? 0,
          comments: feed['comments'] as int? ?? 0,
          shares: 0,
        );
      }

      setState(() {
        _allFeedData
          ..clear()
          ..addAll(filtered);
        _feedData = List<Map<String, dynamic>>.from(filtered);
        _hasMoreData = false;
      });
      _syncCountsWithCounterService();
      _syncUserLikeStates();
    } catch (_) {}
  }

  /// 피드 모드 전환
  void _switchFeedMode(String mode) {
    if (_feedMode == mode) return;
    setState(() => _feedMode = mode);
    if (mode == '팔로잉') {
      _fetchFollowingFeeds();
    } else {
      _fetchFeedsFromSupabase();
    }
  }

  /// CounterService와 카운트 동기화
  void _syncCountsWithCounterService() {
    for (final feed in _feedData) {
      final feedId = feed['id'] as int;
      
      // CounterService에서 실제 카운트 가져오기
      final likeCount = CounterService.instance.getCount('likes', feedId);
      final commentCount = CommentService.instance.getCommentCount(feedId);
      final shareCount = CounterService.instance.getCount('shares', feedId);
      
      // 피드 데이터 업데이트
      feed['likes'] = likeCount;
      feed['comments'] = commentCount;
      feed['shares'] = shareCount;
      
      // CounterService에 댓글 카운트 동기화 (CommentService → CounterService)
      CounterService.instance.updateCommentCount(feedId, commentCount);
    }
    
    // _allFeedData도 동기화
    for (final feed in _allFeedData) {
      final feedId = feed['id'] as int;
      final likeCount = CounterService.instance.getCount('likes', feedId);
      final commentCount = CommentService.instance.getCommentCount(feedId);
      final shareCount = CounterService.instance.getCount('shares', feedId);
      
      feed['likes'] = likeCount;
      feed['comments'] = commentCount;
      feed['shares'] = shareCount;
    }
    
  }
  
  /// 사용자 좋아요 상태 복원 - ChatGPT-4o 권장
  void _syncUserLikeStates() {
    final userId = AuthStateManager.instance.userName;
    final likedFeedsMap = <int, bool>{}; // 🔧 리터럴 대신 생성자 사용
    
    for (int i = 0; i < _feedData.length; i++) {
      final feedId = _feedData[i]['id'] as int;
      final isLiked = CounterService.instance.getUserLikeStatus(userId, feedId);
      likedFeedsMap[i] = isLiked;
    }
    
    // AppStateManager에 저장
    _appStateManager.updateValue('home', 'likedFeeds', likedFeedsMap);
    
    
    // 🔄 UI 강제 업데이트
    if (mounted) {
      setState(() {
        // AppStateManager의 likedFeeds를 직접 업데이트해서 getter가 새 값을 반환하도록 함
        _appStateManager.updateValue('home', 'likedFeeds', Map<int, bool>.from(likedFeedsMap));
      });
    }
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
    setState(() { _isLoadingMore = true; });

    FeedService.instance.fetchFeeds(
      limit: _itemsPerPage,
      offset: _feedData.length,
    ).then((newItems) {
      if (!mounted) return;
      if (newItems.isEmpty) {
        setState(() { _hasMoreData = false; _isLoadingMore = false; });
        return;
      }
      for (final feed in newItems) {
        CounterService.instance.initializeFeedCounts(
          feed['id'] as int,
          likes: feed['likes'] as int? ?? 0,
          comments: feed['comments'] as int? ?? 0,
          shares: 0,
        );
      }
      setState(() {
        _feedData.addAll(newItems);
        _allFeedData.addAll(newItems);
        _hasMoreData = newItems.length >= _itemsPerPage;
        _isLoadingMore = false;
      });
      AppStateManager.instance.updateValue('home', 'feedData', _feedData);
    }).catchError((_) {
      if (!mounted) return;
      setState(() { _isLoadingMore = false; });
    });
  }

  /// 피드 새로고침
  Future<void> _refreshFeeds() async {
    try {
      final feeds = await FeedService.instance.fetchFeeds(limit: _itemsPerPage);
      if (!mounted) return;
      for (final feed in feeds) {
        await CounterService.instance.initializeFeedCounts(
          feed['id'] as int,
          likes: feed['likes'] as int? ?? 0,
          comments: feed['comments'] as int? ?? 0,
          shares: 0,
        );
      }
      setState(() {
        _allFeedData
          ..clear()
          ..addAll(feeds);
        _feedData = List<Map<String, dynamic>>.from(feeds);
        _hasMoreData = feeds.length >= _itemsPerPage;
      });
      AppStateManager.instance.updateValue('home', 'feedData', _feedData);
      _syncCountsWithCounterService();
      _syncUserLikeStates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('새로운 피드가 로드되었습니다!'),
            backgroundColor: AppTheme.accentPink,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
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
              onChanged: (value) async {
                await _updateSearchQuery(value);
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
                      _buildFilterSection('장르', _genres, _selectedGenre, (value) async {
              await _updateSelectedGenre(value);
              _filterFeeds();
            }),
          const SizedBox(height: 16),
          
          // 미디어 타입 필터
                      _buildFilterSection('미디어 타입', _mediaTypes, _selectedMediaType, (value) async {
              await _updateSelectedMediaType(value);
              _filterFeeds();
            }),
          const SizedBox(height: 24),
          
          // 필터 초기화 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                              onPressed: () async {
                  final navigator = Navigator.of(context);
                  await _updateSelectedGenre('전체');
                  await _updateSelectedMediaType('전체');
                  await _updateSearchQuery('');
                  _filterFeeds();
                  navigator.pop();
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

  /// 실시간 업데이트 시작 (더미 피드 생성 비활성화)
  void _startRealtimeUpdates() {
    // 실제 백엔드 연동 시까지 비활성화
    // _realtimeUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
    //   if (_isRealtimeUpdateEnabled && mounted) {
    //     _checkForNewFeeds();
    //   }
    // });
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
  Future<void> _toggleRealtimeUpdates() async {
    await _updateRealtimeUpdateEnabled(!_isRealtimeUpdateEnabled);
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

  // 좋아요 상태 토글 (LikeService → Supabase feed_likes 연동)
  void _toggleLike(int index) async {
    // 로그인 상태 확인
    if (AuthStateManager.instance.requiresLogin) {
      AuthStateManager.instance.showLoginRequiredMessage(context);
      return;
    }

    final feed = _feedData[index];
    final supabaseId = feed['supabaseId'] as String?;
    final messenger = ScaffoldMessenger.of(context);

    // supabaseId가 없는 피드(로컬 임시 피드)는 CounterService 폴백
    if (supabaseId == null) {
      final feedId = feed['id'] as int;
      final userId = AuthStateManager.instance.userName;
      try {
        final newLikedState = await CounterService.instance.toggleLike(userId, feedId);
        final newLikeCount = CounterService.instance.getCount('likes', feedId);
        final currentLikedFeeds = Map<int, bool>.from(_likedFeeds);
        currentLikedFeeds[index] = newLikedState;
        setState(() { _feedData[index]['likes'] = newLikeCount; });
        await _appStateManager.updateValue('home', 'likedFeeds', currentLikedFeeds);
        _appStateManager.updateValue('home', 'feedData', _feedData);
        _recordUserAction(newLikedState ? 'like' : 'unlike', _feedData[index]);
        messenger.showSnackBar(SnackBar(
          content: Text(newLikedState ? '❤️ 좋아요!' : '🤍 좋아요 취소'),
          backgroundColor: AppTheme.accentPink,
          duration: const Duration(seconds: 1),
        ));
      } catch (_) {
        messenger.showSnackBar(const SnackBar(
          content: Text('좋아요 처리 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ));
      }
      return;
    }

    final currentlyLiked = _likedFeeds[index] ?? false;
    try {
      if (currentlyLiked) {
        await LikeService.instance.unlike(supabaseId);
      } else {
        await LikeService.instance.like(supabaseId);
      }
      final newLikedState = !currentlyLiked;
      final currentLikedFeeds = Map<int, bool>.from(_likedFeeds);
      currentLikedFeeds[index] = newLikedState;
      setState(() {
        _feedData[index]['likes'] = (_feedData[index]['likes'] as int? ?? 0) + (newLikedState ? 1 : -1);
      });
      await _appStateManager.updateValue('home', 'likedFeeds', currentLikedFeeds);
      _appStateManager.updateValue('home', 'feedData', _feedData);
      _recordUserAction(newLikedState ? 'like' : 'unlike', _feedData[index]);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(newLikedState ? '❤️ 좋아요!' : '🤍 좋아요 취소'),
        backgroundColor: AppTheme.accentPink,
        duration: const Duration(seconds: 1),
      ));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('좋아요 처리 중 오류가 발생했습니다.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ));
    }
  }

  // 저장 상태 토글
  void _toggleSave(int index) {
    // 로그인 상태 확인
    if (AuthStateManager.instance.requiresLogin) {
      AuthStateManager.instance.showLoginRequiredMessage(context);
      return;
    }

    final currentSavedState = _savedFeeds[index] ?? false;
    final newSavedState = !currentSavedState;
    
    // AppStateManager를 통해 상태 업데이트
    _appStateManager.updateValue('home', 'savedFeeds', {
      ..._savedFeeds,
      index: newSavedState,
    });
    
    // UI 업데이트를 위한 setState 호출
    setState(() {
      // 상태 변경을 UI에 반영
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newSavedState ? '저장됨' : '저장 취소'),
        backgroundColor: AppTheme.accentPink,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// 새 피드 추가 (CounterService 초기화 포함)
  void _addNewFeed(Map<String, dynamic> newFeed) async {
    final feedId = newFeed['id'] as int;
    final messenger = ScaffoldMessenger.of(context);

    // CounterService에 초기 카운트 설정
    await CounterService.instance.initializeFeedCounts(
      feedId,
      likes: newFeed['likes'] ?? 0,
      comments: newFeed['comments'] ?? 0,
      shares: newFeed['shares'] ?? 0,
    );

    // Supabase에 비동기 저장 (논블로킹)
    FeedService.instance.createFeed(
      content: newFeed['content'] as String? ?? '',
      title: newFeed['title'] as String?,
      mediaType: newFeed['mediaType'] as String? ?? 'text',
      mediaUrl: newFeed['mediaUrl'] as String?,
      mediaData: newFeed['mediaData'] as Uint8List?,
    ).catchError((_) => null);

    setState(() {
      _feedData.insert(0, newFeed);
      _allFeedData.insert(0, newFeed);
    });
    
    // AppStateManager에 저장
    AppStateManager.instance.updateValue('home', 'feedData', _feedData);
    
    messenger.showSnackBar(
      const SnackBar(
        content: Text('새 피드가 추가되었습니다!'),
        backgroundColor: AppTheme.accentPink,
        duration: Duration(seconds: 2),
      ),
    );

  }

  // 피드 추가 모달 표시
  void _showAddFeedModal() {
    // 🔒 로그인 상태 확인
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
    // 로그인 상태 확인
    if (AuthStateManager.instance.requiresLogin) {
      AuthStateManager.instance.showLoginRequiredMessage(context);
      return;
    }

    Navigator.of(context).pop(); // 피드 추가 모달 닫기
    
    showDialog(
      context: context,
      builder: (context) => FileUploadModal(
        uploadType: uploadType,
        onUploadComplete: (title, content, mediaData) {
          _addNewFeed({
            'id': DateTime.now().millisecondsSinceEpoch,
            'supabaseId': null,
            'author': AuthStateManager.instance.userName,
            'authorAvatar': AuthStateManager.instance.profileImageBytes != null
                ? MemoryImage(AuthStateManager.instance.profileImageBytes!)
                : '👤',
            'title': title,
            'content': content,
            'genre': '일반',
            'likes': 0,
            'comments': 0,
            'shares': 0,
            'timestamp': '방금 전',
            'mediaType': uploadType,
            'mediaData': mediaData,
            'mediaUrl': null,
            'tags': <String>[],
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
                  'supabaseId': null,
                  'author': AuthStateManager.instance.userName,
                  'authorAvatar': AuthStateManager.instance.profileImageBytes != null
                      ? MemoryImage(AuthStateManager.instance.profileImageBytes!)
                      : '👤',
                  'title': titleController.text,
                  'content': contentController.text,
                  'genre': '일반',
                  'likes': 0,
                  'comments': 0,
                  'shares': 0,
                  'timestamp': '방금 전',
                  'mediaType': 'text',
                  'tags': <String>[],
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
            
              // 전체 | 팔로잉 토글
            _buildFeedModeToggle(),

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
                    return FeedCard(
                      key: ValueKey(feed['id']),
                      feed: feed,
                      index: index,
                      isLiked: _likedFeeds[index] ?? false,
                      isSaved: _savedFeeds[index] == true,
                      isFollowed: _followedUsers.contains(feed['author']),
                      onToggleLike: () => _toggleLike(index),
                      onToggleSave: () => _toggleSave(index),
                      onToggleFollow: () => _toggleFollow(feed['author']),
                      onShowComments: () => _showCommentModal(feed),
                      onShowShare: () => _showShareModal(feed),
                      onShowOptions: () => _showFeedOptions(feed),
                      onTapProfile: () => _showUserProfile(feed['author']),
                    );
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

  /// 전체 | 팔로잉 피드 모드 토글
  Widget _buildFeedModeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: ['전체', '팔로잉'].map((mode) {
          final selected = _feedMode == mode;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _switchFeedMode(mode),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.accentPink : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppTheme.accentPink : AppTheme.grey,
                  ),
                ),
                child: Text(
                  mode,
                  style: TextStyle(
                    color: selected ? AppTheme.white : AppTheme.grey,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
          // 개인화 모드 토글 버튼
          IconButton(
            icon: Icon(
              _isPersonalizedMode ? Icons.person : Icons.people,
              color: _isPersonalizedMode ? AppTheme.accentPink : AppTheme.grey,
            ),
            onPressed: _togglePersonalizedMode,
            tooltip: '개인화 추천',
          ),
          // 오프라인 모드 토글 버튼
          IconButton(
            icon: Icon(
              _isOfflineMode ? Icons.wifi_off : Icons.wifi,
              color: _isOfflineMode ? AppTheme.accentPink : AppTheme.grey,
            ),
            onPressed: _toggleOfflineMode,
            tooltip: '오프라인 모드',
          ),
          // 실시간 업데이트 토글 버튼
          IconButton(
            icon: Icon(
              _isRealtimeUpdateEnabled ? Icons.sync : Icons.sync_disabled,
              color: _isRealtimeUpdateEnabled ? AppTheme.accentPink : AppTheme.grey,
            ),
            onPressed: _toggleRealtimeUpdates,
            tooltip: '실시간 업데이트',
          ),
          // 트렌딩 피드 버튼
          IconButton(
            icon: const Icon(Icons.trending_up, color: AppTheme.white),
            onPressed: _openTrendingFeeds,
            tooltip: '트렌딩 피드',
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppTheme.white),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  );
                  _loadUnreadCount();
                },
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentPink,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_unreadNotificationCount',
                      style: const TextStyle(
                          color: AppTheme.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 댓글 수 업데이트 (CounterService 동기화)
  void _updateCommentCount(int feedId) async {
    final commentCount = CommentService.instance.getCommentCount(feedId);
    
    // CounterService에 댓글 카운트 업데이트
    await CounterService.instance.updateCommentCount(feedId, commentCount);
    
    setState(() {
      final feedIndex = _feedData.indexWhere((feed) => feed['id'] == feedId);
      if (feedIndex != -1) {
        _feedData[feedIndex]['comments'] = commentCount;
      }
      
      final allFeedIndex = _allFeedData.indexWhere((feed) => feed['id'] == feedId);
      if (allFeedIndex != -1) {
        _allFeedData[allFeedIndex]['comments'] = commentCount;
      }
    });
    
    // AppStateManager에 업데이트된 피드 데이터 저장
    AppStateManager.instance.updateValue('home', 'feedData', _feedData);
  }

  /// 댓글 모달 표시
  void _showCommentModal(Map<String, dynamic> feed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.secondaryBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CommentModal(
        feedId: feed['id'],
        feedTitle: feed['title'],
        supabaseFeedId: feed['supabaseId'] as String?,
      ),
    ).then((_) {
      // 모달이 닫힌 후 댓글 수 업데이트
      _updateCommentCount(feed['id']);
    });
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
    // Supabase 업데이트 (논블로킹)
    final supabaseId = updatedFeed['supabaseId'] as String?;
    if (supabaseId != null) {
      final title = updatedFeed['title'] as String? ?? '';
      final body = updatedFeed['content'] as String? ?? '';
      final fullContent = title.isNotEmpty ? '$title\n$body' : body;
      FeedService.instance.updateFeed(supabaseId, content: fullContent).catchError((_) {});
    }

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
    // Supabase ID 추출 후 삭제 (논블로킹)
    final feed = _feedData.firstWhere(
      (f) => f['id'] == feedId,
      orElse: () => _allFeedData.firstWhere((f) => f['id'] == feedId, orElse: () => {}),
    );
    final supabaseId = feed['supabaseId'] as String?;
    if (supabaseId != null) {
      FeedService.instance.deleteFeed(supabaseId).catchError((_) {});
    }

    setState(() {
      _feedData.removeWhere((feed) => feed['id'] == feedId);
      _allFeedData.removeWhere((feed) => feed['id'] == feedId);
    });
  }

  /// 공유 모달 표시 (공유 후 카운트 업데이트)
  void _showShareModal(Map<String, dynamic> feed) {
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
      builder: (context) => ShareModal(feed: feed),
    ).then((_) {
      // 공유 모달이 닫힌 후 공유 카운트 업데이트
      _updateShareCount(feed['id'] as int);
    });
  }

  /// 공유 카운트 업데이트
  void _updateShareCount(int feedId) {
    final shareCount = CounterService.instance.getCount('shares', feedId);
    
    setState(() {
      final feedIndex = _feedData.indexWhere((feed) => feed['id'] == feedId);
      if (feedIndex != -1) {
        _feedData[feedIndex]['shares'] = shareCount;
      }
      
      final allFeedIndex = _allFeedData.indexWhere((feed) => feed['id'] == feedId);
      if (allFeedIndex != -1) {
        _allFeedData[allFeedIndex]['shares'] = shareCount;
      }
    });
    
    // AppStateManager에 업데이트된 피드 데이터 저장
    AppStateManager.instance.updateValue('home', 'feedData', _feedData);
    
  }

  /// 개인화 모드 토글
  Future<void> _togglePersonalizedMode() async {
    await _updatePersonalizedMode(!_isPersonalizedMode);
  }

  /// 오프라인 모드 토글
  Future<void> _toggleOfflineMode() async {
    await _updateOfflineMode(!_isOfflineMode);
  }

  /// 트렌딩 피드 열기
  void _openTrendingFeeds() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TrendingFeedsScreen(),
      ),
    );
  }

  /// 사용자 행동 기록 (추천 시스템용)
  Future<void> _recordUserAction(String action, Map<String, dynamic> feed) async {
    try {
      // TODO: 실제 사용자 행동 기록 구현
      // 현재는 추천 서비스가 업데이트되지 않았으므로 주석 처리
      // await _recommendationService.recordUserAction(action, feed);
    } catch (e) {
      // 오류 무시 (개발 중)
    }
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