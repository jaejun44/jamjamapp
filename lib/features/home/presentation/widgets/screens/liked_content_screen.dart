import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/like_service.dart';

class LikedContentScreen extends StatefulWidget {
  const LikedContentScreen({super.key});

  @override
  State<LikedContentScreen> createState() => _LikedContentScreenState();
}

class _LikedContentScreenState extends State<LikedContentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _likedFeeds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLikedContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLikedContent() async {
    final feeds = await LikeService.instance.getLikedFeeds();
    if (!mounted) return;
    setState(() {
      _likedFeeds = feeds;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('좋아요'),
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
                _buildLikedFeedsTab(),
                _buildLikedMusicTab(),
                _buildLikedUsersTab(),
              ],
            ),
    );
  }

  Widget _buildLikedFeedsTab() {
    if (_likedFeeds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: AppTheme.grey),
            SizedBox(height: 16),
            Text(
              '좋아요한 피드가 없습니다',
              style: TextStyle(color: AppTheme.grey, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              '마음에 드는 피드에 좋아요를 눌러보세요!',
              style: TextStyle(color: AppTheme.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _likedFeeds.length,
      itemBuilder: (context, index) {
        final feed = _likedFeeds[index];
        return _buildFeedCard(feed);
      },
    );
  }

  Widget _buildFeedCard(Map<String, dynamic> feed) {
    final author = feed['author'] as String? ?? '?';
    final initial = author.isNotEmpty ? author[0].toUpperCase() : '?';
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
                    initial,
                    style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    author,
                    style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppTheme.grey),
                  onSelected: (value) => _handleFeedAction(value, feed),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'unlike',
                      child: Row(
                        children: [
                          Icon(Icons.favorite_border, color: AppTheme.accentPink),
                          SizedBox(width: 8),
                          Text('좋아요 취소'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              feed['title'] as String? ?? '',
              style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              feed['content'] as String? ?? '',
              style: const TextStyle(color: AppTheme.white),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (feed['mediaUrl'] != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.accentPink,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.audiotrack, color: AppTheme.white, size: 40),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.favorite, size: 16, color: AppTheme.accentPink),
                Text(' ${feed['likes']}', style: const TextStyle(color: AppTheme.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikedMusicTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note, size: 64, color: AppTheme.grey),
          SizedBox(height: 16),
          Text('준비 중', style: TextStyle(color: AppTheme.grey, fontSize: 18)),
          SizedBox(height: 8),
          Text('음악 좋아요 기능이 곧 추가됩니다', style: TextStyle(color: AppTheme.grey)),
        ],
      ),
    );
  }

  Widget _buildLikedUsersTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: AppTheme.grey),
          SizedBox(height: 16),
          Text('준비 중', style: TextStyle(color: AppTheme.grey, fontSize: 18)),
          SizedBox(height: 8),
          Text('사용자 좋아요 기능이 곧 추가됩니다', style: TextStyle(color: AppTheme.grey)),
        ],
      ),
    );
  }

  void _handleFeedAction(String action, Map<String, dynamic> feed) {
    if (action == 'unlike') _unlikeFeed(feed);
  }

  Future<void> _unlikeFeed(Map<String, dynamic> feed) async {
    final feedId = feed['id'] as String;
    await LikeService.instance.unlike(feedId);
    if (!mounted) return;
    setState(() {
      _likedFeeds.removeWhere((item) => item['id'] == feedId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('피드 좋아요가 취소되었습니다'),
        backgroundColor: AppTheme.accentPink,
      ),
    );
  }
}
