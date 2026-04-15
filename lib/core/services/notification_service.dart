import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jamjamapp/core/services/supabase_service.dart';

/// 알림 비즈니스 로직 서비스
/// Supabase notifications 테이블 연동 담당
class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  // ---------------------------------------------------------------------------
  // 내부 유틸
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _mapRow(Map<String, dynamic> row) {
    return {
      'id': row['id'] as String? ?? '',
      'type': row['type'] as String? ?? '',
      'payload': row['payload'] as Map<String, dynamic>? ?? {},
      'read': row['read'] as bool? ?? false,
      'createdAt': row['created_at'] as String?,
    };
  }

  // ---------------------------------------------------------------------------
  // 공개 API
  // ---------------------------------------------------------------------------

  /// 내 알림 목록
  Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 30,
    bool unreadOnly = false,
  }) async {
    try {
      final rows = await SupabaseService.instance.getNotifications(
        limit: limit,
        unreadOnly: unreadOnly,
      );
      return rows.map(_mapRow).toList();
    } catch (_) {
      return [];
    }
  }

  /// 읽지 않은 알림 수
  Future<int> getUnreadCount() async {
    try {
      return await SupabaseService.instance.getUnreadNotificationCount();
    } catch (_) {
      return 0;
    }
  }

  /// 특정 알림 읽음 처리
  Future<void> markRead(String notificationId) async {
    try {
      await SupabaseService.instance.markNotificationRead(notificationId);
    } catch (_) {}
  }

  /// 전체 읽음 처리
  Future<void> markAllRead() async {
    try {
      await SupabaseService.instance.markAllNotificationsRead();
    } catch (_) {}
  }

  /// 실시간 알림 구독
  RealtimeChannel subscribe(
    void Function(Map<String, dynamic> notification) onNew,
  ) {
    return SupabaseService.instance.subscribeToNotifications(
      (payload) => onNew(_mapRow(payload)),
    );
  }

  /// 구독 해제
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await Supabase.instance.client.removeChannel(channel);
  }
}
