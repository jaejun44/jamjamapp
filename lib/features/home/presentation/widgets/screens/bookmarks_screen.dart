import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/bookmark_service.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _bookmarkedFeeds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookmarks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final feeds = await BookmarkService.instance.getBookmarkedFeeds();
    if (!mounted) return;
    setState(() {
      _bookmarkedFeeds = feeds;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('북마크'),
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
                _buildBookmarkedFeedsTab(),
                _buildBookmarkedMusicTab(),
                _buildBookmarkedUsersTab(),
              ],
            ),
    );
  }

  Widget _buildBookmarkedFeedsTab() {
    if (_bookmarkedFeeds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: AppTheme.grey),
            SizedBox(height: 16),
            Text(
              '북마크한 피드가 없습니다',
              style: TextStyle(color: AppTheme.grey, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              '나중에 보고 싶은 피드를 북마크해보세요!',
              style: TextStyle(color: AppTheme.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookmarkedFeeds.length,
      itemBuilder: (context, index) {
        final feed = _bookmarkedFeeds[index];
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
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.bookmark_border, color: AppTheme.accentPink),
                          SizedBox(width: 8),
                          Text('북마크 제거'),
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
                const Icon(Icons.favorite, size: 16, color: AppTheme.grey),
                Text(' ${feed['likes']}', style: const TextStyle(color: AppTheme.grey)),
                const Spacer(),
                const Icon(Icons.bookmark, size: 16, color: AppTheme.accentPink),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkedMusicTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note, size: 64, color: AppTheme.grey),
          SizedBox(height: 16),
          Text('준비 중', style: TextStyle(color: AppTheme.grey, fontSize: 18)),
          SizedBox(height: 8),
          Text('음악 북마크 기능이 곧 추가됩니다', style: TextStyle(color: AppTheme.grey)),
        ],
      ),
    );
  }

  Widget _buildBookmarkedUsersTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: AppTheme.grey),
          SizedBox(height: 16),
          Text('준비 중', style: TextStyle(color: AppTheme.grey, fontSize: 18)),
          SizedBox(height: 8),
          Text('사용자 북마크 기능이 곧 추가됩니다', style: TextStyle(color: AppTheme.grey)),
        ],
      ),
    );
  }

  void _handleFeedAction(String action, Map<String, dynamic> feed) {
    if (action == 'remove') _removeBookmarkFeed(feed);
  }

  Future<void> _removeBookmarkFeed(Map<String, dynamic> feed) async {
    final feedId = feed['id'] as String;
    await BookmarkService.instance.unbookmark(feedId);
    if (!mounted) return;
    setState(() {
      _bookmarkedFeeds.removeWhere((item) => item['id'] == feedId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('피드 북마크가 제거되었습니다'),
        backgroundColor: AppTheme.accentPink,
      ),
    );
  }
}