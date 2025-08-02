import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'user_profile_screen.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  
  // 임시 검색 데이터
  final List<Map<String, dynamic>> _allMusicians = [
    {'name': 'JamMaster1', 'genre': '재즈', 'instrument': '기타', 'followers': 1200},
    {'name': 'MusicLover2', 'genre': '팝', 'instrument': '피아노', 'followers': 800},
    {'name': 'GuitarHero3', 'genre': '락', 'instrument': '기타', 'followers': 2100},
    {'name': 'Pianist4', 'genre': '클래식', 'instrument': '피아노', 'followers': 950},
    {'name': 'Drummer5', 'genre': '록', 'instrument': '드럼', 'followers': 1500},
    {'name': 'Vocalist6', 'genre': '팝', 'instrument': '보컬', 'followers': 1800},
    {'name': 'Producer7', 'genre': '일렉트로닉', 'instrument': '프로듀서', 'followers': 2200},
    {'name': 'Composer8', 'genre': '클래식', 'instrument': '작곡가', 'followers': 1100},
  ];

  List<Map<String, dynamic>> _filteredMusicians = [];

  @override
  void initState() {
    super.initState();
    _filteredMusicians = _allMusicians;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });

    // 검색 시뮬레이션
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
          if (query.isEmpty) {
            _filteredMusicians = _allMusicians;
          } else {
            _filteredMusicians = _allMusicians.where((musician) {
              return musician['name'].toLowerCase().contains(query.toLowerCase()) ||
                     musician['genre'].toLowerCase().contains(query.toLowerCase()) ||
                     musician['instrument'].toLowerCase().contains(query.toLowerCase());
            }).toList();
          }
        });
      }
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '필터 옵션',
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
            
            // 장르 필터
            _buildFilterSection('장르', ['재즈', '팝', '락', '클래식', '일렉트로닉', '힙합']),
            const SizedBox(height: 16),
            
            // 악기 필터
            _buildFilterSection('악기', ['기타', '피아노', '드럼', '보컬', '베이스', '색소폰']),
            const SizedBox(height: 24),
            
            // 필터 적용 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('필터가 적용되었습니다'),
                      backgroundColor: AppTheme.accentPink,
                    ),
                  );
                },
                child: const Text('필터 적용'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options) {
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) => ActionChip(
            label: Text(option),
            backgroundColor: AppTheme.primaryBlack,
            labelStyle: const TextStyle(color: AppTheme.white),
            onPressed: () {
              // TODO: 필터 선택 로직
            },
          )).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('검색'),
      ),
      body: Column(
        children: [
          // 검색바
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: '음악인, 장르, 악기로 검색...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune, color: AppTheme.grey),
                  onPressed: _showFilterModal,
                ),
              ),
            ),
          ),
          
          // 인기 검색어
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '인기 검색어',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip('팝', context),
                    _buildChip('락', context),
                    _buildChip('재즈', context),
                    _buildChip('클래식', context),
                    _buildChip('일렉트로닉', context),
                    _buildChip('힙합', context),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 추천 음악인
          Expanded(
            child: _isSearching
                ? const Center(
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
                  )
                : _filteredMusicians.isEmpty && _searchQuery.isNotEmpty
                    ? Center(
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
                              '다른 키워드로 검색해보세요',
                              style: TextStyle(
                                color: AppTheme.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredMusicians.length,
                        itemBuilder: (context, index) {
                          return _buildMusicianCard(context, index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppTheme.secondaryBlack,
      labelStyle: const TextStyle(color: AppTheme.white),
      onPressed: () {
        // TODO: 검색 실행
      },
    );
  }

  Widget _buildMusicianCard(BuildContext context, int index) {
    final musician = _filteredMusicians[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: GestureDetector(
          onTap: () => _showUserProfile(musician['name']),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: AppTheme.accentPink,
            child: const Icon(Icons.person, color: AppTheme.white, size: 30),
          ),
        ),
        title: GestureDetector(
          onTap: () => _showUserProfile(musician['name']),
          child: Text(
            musician['name'],
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${musician['genre']} • ${musician['instrument']}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '팔로워 ${musician['followers']}명',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.grey,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${musician['name']}을(를) 팔로우했습니다'),
                backgroundColor: AppTheme.accentPink,
                duration: const Duration(seconds: 1),
              ),
            );
          },
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
        onTap: () => _showUserProfile(musician['name']),
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
} 