import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/search_service.dart';
import 'package:jamjamapp/core/services/auth_state_manager.dart';
import 'package:jamjamapp/core/services/profile_image_manager.dart';
import 'user_profile_screen.dart';
import 'dart:async';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SearchService _searchService = SearchService();
  
  // 검색 상태 관리
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isLoadingMore = false;
  bool _isLoadingSuggestions = false;
  Timer? _searchDebounceTimer;
  Timer? _suggestionDebounceTimer;
  
  // 필터 상태 관리
  Set<String> _selectedGenres = LinkedHashSet<String>();
  Set<String> _selectedInstruments = LinkedHashSet<String>();
  Set<String> _selectedLocations = LinkedHashSet<String>();
  String _sortBy = 'relevance'; // 'relevance', 'name', 'followers', 'recent', 'posts'
  String _sortOrder = 'desc'; // 'asc', 'desc'
  
  // 고급 필터
  int? _minFollowers;
  int? _maxFollowers;
  bool? _isOnline;
  bool? _isVerified;
  
  // 검색 히스토리
  List<String> _searchHistory = [];
  Set<String> _favoriteSearches = LinkedHashSet<String>();
  List<String> _searchSuggestions = [];
  
  // 페이지네이션
  int _currentPage = 1;
  bool _hasMoreData = true;
  static const int _itemsPerPage = 20;
  
  // 검색 결과
  List<Map<String, dynamic>> _allMusicians = [];
  List<Map<String, dynamic>> _filteredMusicians = [];
  List<Map<String, dynamic>> _displayedMusicians = [];
  
  // 검색 통계
  Map<String, dynamic> _searchStats = LinkedHashMap<String, dynamic>();
  
  // 에러 상태
  String? _errorMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeSearchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounceTimer?.cancel();
    _suggestionDebounceTimer?.cancel();
    super.dispose();
  }

  /// 검색 데이터 초기화
  Future<void> _initializeSearchData() async {
    try {
      // 확장된 음악인 데이터 로드
      _allMusicians = _loadExtendedMusicianData();
      
      // 검색 서비스 사전 로드
      await _searchService.preloadSearchData(_allMusicians);
      
      // 검색 히스토리 로드
      await _loadSearchHistory();
      
      // 초기 검색 실행
      _filteredMusicians = _allMusicians;
      _loadMoreData();
      
      // 검색 통계 생성
      _updateSearchStats();
      
    } catch (e) {
      _setError('검색 데이터 초기화 중 오류가 발생했습니다: $e');
    }
  }

  /// 확장된 음악인 데이터 로드
  List<Map<String, dynamic>> _loadExtendedMusicianData() {
    return [
      {
        'id': 1,
        'name': 'JamMaster1',
        'genre': '재즈',
        'instrument': '기타',
        'location': '서울',
        'followers': 1200,
        'following': 450,
        'posts': 89,
        'bio': '재즈 기타리스트입니다 🎸',
        'avatar': '🎸',
        'isOnline': true,
        'lastActive': DateTime.now().subtract(const Duration(minutes: 5)),
        'tags': ['재즈', '기타', '서울', '프로'],
        'verified': true,
      },
      {
        'id': 2,
        'name': 'MusicLover2',
        'genre': '팝',
        'instrument': '피아노',
        'location': '부산',
        'followers': 800,
        'following': 320,
        'posts': 156,
        'bio': '팝 피아니스트입니다 🎹',
        'avatar': '🎹',
        'isOnline': false,
        'lastActive': DateTime.now().subtract(const Duration(hours: 2)),
        'tags': ['팝', '피아노', '부산', '인디'],
        'verified': false,
      },
      {
        'id': 3,
        'name': 'GuitarHero3',
        'genre': '락',
        'instrument': '기타',
        'location': '대구',
        'followers': 2100,
        'following': 890,
        'posts': 234,
        'bio': '락 기타리스트입니다 🎸',
        'avatar': '🎸',
        'isOnline': true,
        'lastActive': DateTime.now().subtract(const Duration(minutes: 1)),
        'tags': ['락', '기타', '대구', '프로'],
        'verified': true,
      },
      {
        'id': 4,
        'name': 'Pianist4',
        'genre': '클래식',
        'instrument': '피아노',
        'location': '인천',
        'followers': 950,
        'following': 120,
        'posts': 67,
        'bio': '클래식 피아니스트입니다 🎹',
        'avatar': '🎹',
        'isOnline': false,
        'lastActive': DateTime.now().subtract(const Duration(days: 1)),
        'tags': ['클래식', '피아노', '인천', '학생'],
        'verified': false,
      },
      {
        'id': 5,
        'name': 'Drummer5',
        'genre': '록',
        'instrument': '드럼',
        'location': '광주',
        'followers': 1500,
        'following': 670,
        'posts': 189,
        'bio': '록 드러머입니다 🥁',
        'avatar': '🥁',
        'isOnline': true,
        'lastActive': DateTime.now().subtract(const Duration(minutes: 10)),
        'tags': ['록', '드럼', '광주', '프로'],
        'verified': true,
      },
      {
        'id': 6,
        'name': 'Vocalist6',
        'genre': '팝',
        'instrument': '보컬',
        'location': '대전',
        'followers': 1800,
        'following': 450,
        'posts': 145,
        'bio': '팝 보컬리스트입니다 🎤',
        'avatar': '🎤',
        'isOnline': false,
        'lastActive': DateTime.now().subtract(const Duration(hours: 3)),
        'tags': ['팝', '보컬', '대전', '인디'],
        'verified': false,
      },
      {
        'id': 7,
        'name': 'Producer7',
        'genre': '일렉트로닉',
        'instrument': '프로듀서',
        'location': '서울',
        'followers': 2200,
        'following': 890,
        'posts': 312,
        'bio': '일렉트로닉 프로듀서입니다 🎧',
        'avatar': '🎧',
        'isOnline': true,
        'lastActive': DateTime.now().subtract(const Duration(minutes: 2)),
        'tags': ['일렉트로닉', '프로듀서', '서울', '프로'],
        'verified': true,
      },
      {
        'id': 8,
        'name': 'Composer8',
        'genre': '클래식',
        'instrument': '작곡가',
        'location': '서울',
        'followers': 1100,
        'following': 230,
        'posts': 78,
        'bio': '클래식 작곡가입니다 🎼',
        'avatar': '🎼',
        'isOnline': false,
        'lastActive': DateTime.now().subtract(const Duration(days: 2)),
        'tags': ['클래식', '작곡가', '서울', '학생'],
        'verified': false,
      },
      {
        'id': 9,
        'name': 'BassMaster9',
        'genre': '재즈',
        'instrument': '베이스',
        'location': '부산',
        'followers': 950,
        'following': 340,
        'posts': 123,
        'bio': '재즈 베이시스트입니다 🎸',
        'avatar': '🎸',
        'isOnline': true,
        'lastActive': DateTime.now().subtract(const Duration(minutes: 15)),
        'tags': ['재즈', '베이스', '부산', '프로'],
        'verified': true,
      },
      {
        'id': 10,
        'name': 'Saxophonist10',
        'genre': '재즈',
        'instrument': '색소폰',
        'location': '서울',
        'followers': 1350,
        'following': 560,
        'posts': 167,
        'bio': '재즈 색소폰 연주자입니다 🎷',
        'avatar': '🎷',
        'isOnline': false,
        'lastActive': DateTime.now().subtract(const Duration(hours: 1)),
        'tags': ['재즈', '색소폰', '서울', '프로'],
        'verified': true,
      },
    ];
  }

  /// 검색 히스토리 로드
  Future<void> _loadSearchHistory() async {
    try {
      _searchHistory = await _searchService.getSearchHistory();
      _favoriteSearches = await _searchService.getFavoriteSearches();
    } catch (e) {
      _setError('검색 히스토리 로드 중 오류가 발생했습니다: $e');
    }
  }

  /// 실시간 검색 (디바운싱 적용)
  void _performSearch(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeAdvancedSearch(query);
    });
  }

  /// 고급 검색 실행
  Future<void> _executeAdvancedSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _searchQuery = query;
      _isSearching = true;
      _currentPage = 1;
      _hasMoreData = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // 고급 검색 실행
      List<Map<String, dynamic>> results = await _searchService.performAdvancedSearch(
        query: query,
        musicians: _allMusicians,
        genres: _selectedGenres,
        instruments: _selectedInstruments,
        locations: _selectedLocations,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        minFollowers: _minFollowers,
        maxFollowers: _maxFollowers,
        isOnline: _isOnline,
        isVerified: _isVerified,
      );

      if (mounted) {
        setState(() {
          _isSearching = false;
          _filteredMusicians = results;
          _displayedMusicians.clear();
          _loadMoreData();
          _updateSearchStats();
        });
      }

    } catch (e) {
      if (mounted) {
        _setError('검색 중 오류가 발생했습니다: $e');
      }
    }
  }

  /// 검색 제안 생성
  void _generateSearchSuggestions(String partialQuery) {
    _suggestionDebounceTimer?.cancel();
    _suggestionDebounceTimer = Timer(const Duration(milliseconds: 200), () async {
      if (!mounted) return;

      setState(() {
        _isLoadingSuggestions = true;
      });

      try {
        List<String> suggestions = await _searchService.getSearchSuggestions(
          partialQuery,
          _allMusicians,
        );

        if (mounted) {
          setState(() {
            _searchSuggestions = suggestions;
            _isLoadingSuggestions = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _searchSuggestions = [];
            _isLoadingSuggestions = false;
          });
        }
      }
    });
  }

  /// 더 많은 데이터 로드
  void _loadMoreData() {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    // 페이지네이션 시뮬레이션
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        final startIndex = (_currentPage - 1) * _itemsPerPage;
        final endIndex = startIndex + _itemsPerPage;
        
        if (startIndex < _filteredMusicians.length) {
          final newItems = _filteredMusicians.skip(startIndex).take(_itemsPerPage).toList();
          setState(() {
            _displayedMusicians.addAll(newItems);
            _currentPage++;
            _hasMoreData = endIndex < _filteredMusicians.length;
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

  /// 검색 통계 업데이트
  void _updateSearchStats() {
    _searchStats = _searchService.generateSearchStats(_filteredMusicians);
  }

  /// 에러 처리
  void _setError(String error) {
    setState(() {
      _errorMessage = error;
      _hasError = true;
      _isSearching = false;
      _isLoadingSuggestions = false;
    });
  }

  /// 에러 클리어
  void _clearError() {
    setState(() {
      _errorMessage = null;
      _hasError = false;
    });
  }

  /// 검색 제안 선택
  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _executeAdvancedSearch(suggestion);
    setState(() {
      _searchSuggestions = [];
    });
  }

  /// 즐겨찾기 토글
  Future<void> _toggleFavoriteSearch(String query) async {
    await _searchService.toggleFavoriteSearch(query);
    _favoriteSearches = await _searchService.getFavoriteSearches();
    setState(() {});
  }

  /// 검색 결과 내보내기
  Future<void> _exportSearchResults() async {
    try {
      String exportData = await _searchService.exportSearchResults(_filteredMusicians);
      // TODO: 파일 다운로드 또는 공유 기능 구현
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('검색 결과가 내보내기되었습니다'),
          backgroundColor: AppTheme.accentPink,
        ),
      );
    } catch (e) {
      _setError('검색 결과 내보내기 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            // 검색 헤더
            _buildSearchHeader(),
            
            // 에러 메시지
            if (_hasError) _buildErrorMessage(),
            
            // 검색 결과
            Expanded(
              child: _isSearching
                  ? _buildLoadingIndicator()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 검색바
          TextField(
            controller: _searchController,
            onChanged: (value) {
              _performSearch(value);
              _generateSearchSuggestions(value);
            },
            style: const TextStyle(color: AppTheme.white),
            decoration: InputDecoration(
              hintText: '음악인, 장르, 악기, 지역으로 검색...',
              hintStyle: const TextStyle(color: AppTheme.grey),
              prefixIcon: const Icon(Icons.search, color: AppTheme.grey),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.grey),
                      onPressed: () {
                        _searchController.clear();
                        _executeAdvancedSearch('');
                        setState(() {
                          _searchSuggestions = [];
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: AppTheme.grey),
                    onPressed: _showAdvancedFilterModal,
                  ),
                ],
              ),
              filled: true,
              fillColor: AppTheme.secondaryBlack,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 검색 제안
          if (_searchSuggestions.isNotEmpty) _buildSearchSuggestions(),
          
          // 인기 검색어 (검색어가 없을 때)
          if (_searchQuery.isEmpty) _buildPopularSearches(),
          
          // 검색 통계
          if (_searchStats.isNotEmpty) _buildSearchStats(),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _searchSuggestions[index];
          return ListTile(
            leading: const Icon(Icons.search, color: AppTheme.grey),
            title: Text(
              suggestion,
              style: const TextStyle(color: AppTheme.white),
            ),
            onTap: () => _selectSuggestion(suggestion),
          );
        },
      ),
    );
  }

  Widget _buildPopularSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '인기 검색어',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            '재즈', '팝', '락', '기타', '피아노', '서울', '프로', '인디'
          ].map((tag) => ActionChip(
            label: Text(tag),
            backgroundColor: AppTheme.secondaryBlack,
            labelStyle: const TextStyle(color: AppTheme.white),
            onPressed: () {
              _searchController.text = tag;
              _executeAdvancedSearch(tag);
            },
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: AppTheme.accentPink, size: 16),
          const SizedBox(width: 8),
          Text(
            '검색 결과: ${_searchStats['total'] ?? 0}개',
            style: const TextStyle(color: AppTheme.white, fontSize: 12),
          ),
          const SizedBox(width: 16),
          if (_searchStats['online'] != null)
            Text(
              '온라인: ${_searchStats['online']}명',
              style: const TextStyle(color: AppTheme.grey, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? '알 수 없는 오류가 발생했습니다',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 16),
            onPressed: _clearError,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPink),
          ),
          SizedBox(height: 16),
          Text(
            '검색 중...',
            style: TextStyle(color: AppTheme.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_displayedMusicians.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoResults();
    }
    
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _loadMoreData();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _displayedMusicians.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _displayedMusicians.length) {
            return _buildLoadMoreIndicator();
          }
          return _buildMusicianCard(_displayedMusicians[index]);
        },
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.grey,
          ),
          const SizedBox(height: 16),
          Text(
            '검색 결과가 없습니다',
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 키워드나 필터를 시도해보세요',
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPink),
        ),
      ),
    );
  }

  Widget _buildMusicianCard(Map<String, dynamic> musician) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            GestureDetector(
              onTap: () => _showUserProfile(musician['name']),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.accentPink,
                backgroundImage: musician['name'] == AuthStateManager.instance.userName && 
                                AuthStateManager.instance.profileImageBytes != null
                    ? MemoryImage(AuthStateManager.instance.profileImageBytes!)
                    : null,
                child: musician['name'] == AuthStateManager.instance.userName && 
                       AuthStateManager.instance.profileImageBytes != null
                    ? null
                    : Text(
                        musician['avatar'],
                        style: const TextStyle(fontSize: 24),
                      ),
              ),
            ),
            if (musician['isOnline'])
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.secondaryBlack, width: 2),
                  ),
                ),
              ),
            if (musician['verified'])
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentPink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: AppTheme.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        title: GestureDetector(
          onTap: () => _showUserProfile(musician['name']),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  musician['name'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${musician['followers']}명',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.grey,
                ),
              ),
            ],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              musician['bio'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPink.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    musician['genre'],
                    style: TextStyle(
                      color: AppTheme.accentPink,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    musician['instrument'],
                    style: const TextStyle(
                      color: AppTheme.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    musician['location'],
                    style: const TextStyle(
                      color: AppTheme.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _followMusician(musician),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPink,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 32),
              ),
              child: const Text(
                '팔로우',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getTimeAgo(musician['lastActive']),
              style: const TextStyle(
                color: AppTheme.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _followMusician(Map<String, dynamic> musician) {
    // 로그인 상태 확인
    if (AuthStateManager.instance.requiresLogin) {
      AuthStateManager.instance.showLoginRequiredMessage(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${musician['name']}을(를) 팔로우했습니다'),
        backgroundColor: AppTheme.accentPink,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _getTimeAgo(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);
    
    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
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

  // 고급 필터 모달 (기존 구현 유지)
  void _showAdvancedFilterModal() {
    // TODO: 고급 필터 모달 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('고급 필터 기능이 준비 중입니다'),
        backgroundColor: AppTheme.accentPink,
      ),
    );
  }
} 