import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/notification_service.dart';
import '../shared/notification_tile.dart';

/// 알림 화면 — 전체/안읽음 탭 + 실시간 구독
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _unread = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
    _channel = NotificationService.instance.subscribe((notification) {
      if (!mounted) return;
      setState(() {
        _all.insert(0, notification);
        if (!(notification['read'] as bool? ?? false)) {
          _unread.insert(0, notification);
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_channel != null) {
      NotificationService.instance.unsubscribe(_channel!);
    }
    super.dispose();
  }

  Future<void> _load() async {
    final all = await NotificationService.instance.getNotifications();
    final unread = await NotificationService.instance
        .getNotifications(unreadOnly: true);
    if (!mounted) return;
    setState(() {
      _all = all;
      _unread = unread;
      _isLoading = false;
    });
  }

  Future<void> _markAllRead() async {
    await NotificationService.instance.markAllRead();
    if (!mounted) return;
    setState(() {
      _all = _all.map((n) => {...n, 'read': true}).toList();
      _unread = [];
    });
  }

  Future<void> _markRead(Map<String, dynamic> notification) async {
    if (notification['read'] as bool? ?? false) return;
    final id = notification['id'] as String;
    await NotificationService.instance.markRead(id);
    if (!mounted) return;
    setState(() {
      _all = _all.map((n) => n['id'] == id ? {...n, 'read': true} : n).toList();
      _unread = _unread.where((n) => n['id'] != id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        title: const Text(
          '알림',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_unread.isNotEmpty)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                '모두 읽음',
                style: TextStyle(color: AppTheme.accentPink, fontSize: 13),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentPink,
          labelColor: AppTheme.accentPink,
          unselectedLabelColor: AppTheme.grey,
          tabs: [
            const Tab(text: '전체'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('안읽음'),
                  if (_unread.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_unread.length}',
                        style: const TextStyle(
                            color: AppTheme.white, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentPink),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_all),
                _buildList(_unread),
              ],
            ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          '알림이 없습니다',
          style: TextStyle(color: AppTheme.grey, fontSize: 16),
        ),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(color: AppTheme.secondaryBlack, height: 1),
      itemBuilder: (_, i) => NotificationTile(
        notification: items[i],
        onTap: () => _markRead(items[i]),
      ),
    );
  }
}
