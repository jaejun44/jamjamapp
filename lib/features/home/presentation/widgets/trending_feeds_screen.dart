import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'dart:math';

class TrendingFeedsScreen extends StatefulWidget {
  const TrendingFeedsScreen({super.key});

  @override
  State<TrendingFeedsScreen> createState() => _TrendingFeedsScreenState();
}

class _TrendingFeedsScreenState extends State<TrendingFeedsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeFrame = '오늘';
  String _selectedCategory = '전체';
  
  final List<String> _timeFrames = ['오늘', '이번 주', '이번 달'];
  final List<String> _categories = ['전체', '음악', '라이브', '커버', '오리지널'];
  
  List<Map<String, dynamic>> _trendingFeeds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _timeFrames.length, vsync: this);
    _loadTrendingFeeds();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 트렌딩 피드 로드
  Future<void> _loadTrendingFeeds() async {
    setState(() {
      _isLoading = true;
    });

    // 시뮬레이션된 로딩 시간
    await Future.delayed(const Duration(seconds: 1));

    // 트렌딩 피드 데이터 생성
    _trendingFeeds = _generateTrendingFeeds();

    setState(() {
      _isLoading = false;
    });
  }

  /// 트렌딩 피드 데이터 생성
  List<Map<String, dynamic>> _generateTrendingFeeds() {
    final random = Random();
    final feeds = <Map<String, dynamic>>[];
    
    for (int i = 0; i < 20; i++) {
      final likes = 100 + random.nextInt(5000);
      final comments = 10 + random.nextInt(500);
      final shares = 5 + random.nextInt(200);
      final views = 1000 + random.nextInt(50000);
      
      // 트렌딩 점수 계산 (좋아요, 댓글, 공유, 조회수 기반)
      final trendingScore = (likes * 0.4) + (comments * 0.3) + (shares * 0.2) + (views * 0.1);
      
      feeds.add({
        'id': i + 1,
        'author': 'TrendingArtist${i + 1}',
        'authorAvatar': ['🎸', '🎹', '🎷', '🥁', '🎻', '🎺', '🎼', '🎵'][random.nextInt(8)],
        'title': '트렌딩 음악 ${i + 1}',
        'content': '인기 급상승 중인 음악입니다! 🔥 #트렌딩 #인기 #음악',
        'genre': ['팝', '재즈', '락', '클래식', '일렉트로닉', '힙합'][random.nextInt(6)],
        'likes': likes,
        'comments': comments,
        'shares': shares,
        'views': views,
        'trendingScore': trendingScore,
        'timestamp': '${random.nextInt(24)}시간 전',
        'mediaType': ['video', 'audio', 'image'][random.nextInt(3)],
        'tags': ['트렌딩', '인기', '음악', '연주'],
        'category': ['음악', '라이브', '커버', '오리지널'][random.nextInt(4)],
        'trendingRank': i + 1,
      });
    }
    
    // 트렌딩 점수순으로 정렬
    feeds.sort((a, b) => b['trendingScore'].compareTo(a['trendingScore']));
    
    // 순위 업데이트
    for (int i = 0; i < feeds.length; i++) {
      feeds[i]['trendingRank'] = i + 1;
    }
    
    return feeds;
  }

  /// 필터링된 피드 가져오기
  List<Map<String, dynamic>> get _filteredFeeds {
    return _trendingFeeds.where((feed) {
      if (_selectedCategory != '전체' && feed['category'] != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(),
            
            // 탭바
            _buildTabBar(),
            
            // 카테고리 필터
            _buildCategoryFilter(),
            
            // 피드 목록
            Expanded(
              child: _isLoading
                ? _buildLoadingIndicator()
                : _buildTrendingFeedsList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 헤더 빌드
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          ),
          const Expanded(
            child: Text(
              '트렌딩',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: _loadTrendingFeeds,
            icon: const Icon(Icons.refresh, color: AppTheme.white),
          ),
        ],
      ),
    );
  }

  /// 탭바 빌드
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.accentPink,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: AppTheme.white,
        unselectedLabelColor: AppTheme.grey,
        tabs: _timeFrames.map((timeFrame) => Tab(text: timeFrame)).toList(),
        onTap: (index) {
          setState(() {
            _selectedTimeFrame = _timeFrames[index];
          });
        },
      ),
    );
  }

  /// 카테고리 필터 빌드
  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentPink : AppTheme.secondaryBlack,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.accentPink : AppTheme.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? AppTheme.white : AppTheme.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 로딩 인디케이터
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.accentPink,
          ),
          SizedBox(height: 16),
          Text(
            '트렌딩 피드를 로드하는 중...',
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 트렌딩 피드 목록
  Widget _buildTrendingFeedsList() {
    final filteredFeeds = _filteredFeeds;
    
    if (filteredFeeds.isEmpty) {
      return const Center(
        child: Text(
          '트렌딩 피드가 없습니다.',
          style: TextStyle(
            color: AppTheme.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredFeeds.length,
      itemBuilder: (context, index) {
        final feed = filteredFeeds[index];
        return _buildTrendingFeedCard(feed, index);
      },
    );
  }

  /// 트렌딩 피드 카드
  Widget _buildTrendingFeedCard(Map<String, dynamic> feed, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // 트렌딩 순위 헤더
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlack,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // 순위 배지
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getRankColor(feed['trendingRank']),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${feed['trendingRank']}',
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // 트렌딩 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '트렌딩 ${feed['trendingRank']}위',
                        style: const TextStyle(
                          color: AppTheme.accentPink,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_selectedTimeFrame} 인기 급상승',
                        style: const TextStyle(
                          color: AppTheme.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 트렌딩 점수
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPink.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🔥 ${feed['trendingScore'].toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.accentPink,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 피드 내용
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 작성자 정보
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.accentPink,
                      child: Text(
                        feed['authorAvatar'],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feed['author'],
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            feed['timestamp'],
                            style: const TextStyle(
                              color: AppTheme.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPink.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        feed['category'],
                        style: const TextStyle(
                          color: AppTheme.accentPink,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // 제목
                Text(
                  feed['title'],
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 내용
                Text(
                  feed['content'],
                  style: const TextStyle(
                    color: AppTheme.grey,
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // 통계
                Row(
                  children: [
                    _buildStatItem(Icons.favorite, '${feed['likes']}'),
                    const SizedBox(width: 16),
                    _buildStatItem(Icons.chat_bubble, '${feed['comments']}'),
                    const SizedBox(width: 16),
                    _buildStatItem(Icons.share, '${feed['shares']}'),
                    const SizedBox(width: 16),
                    _buildStatItem(Icons.remove_red_eye, '${feed['views']}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 통계 아이템
  Widget _buildStatItem(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.grey, size: 16),
        const SizedBox(width: 4),
        Text(
          count,
          style: const TextStyle(
            color: AppTheme.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// 순위별 색상
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return AppTheme.accentPink;
    }
  }
} 