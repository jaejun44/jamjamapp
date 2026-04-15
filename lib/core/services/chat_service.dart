import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jamjamapp/core/services/supabase_service.dart';

/// Chat 서비스
/// Supabase chat_rooms / chat_members / chat_messages 연동 담당
class ChatService {
  static final ChatService _instance = ChatService._internal();
  static ChatService get instance => _instance;
  ChatService._internal();

  // roomId → RealtimeChannel
  final Map<String, RealtimeChannel> _subscriptions = {};

  // ---------------------------------------------------------------------------
  // 내부 유틸
  // ---------------------------------------------------------------------------

  String _formatTimestamp(String? isoString) {
    if (isoString == null) return '방금 전';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return '방금 전';
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) {
        final h = dt.hour;
        final m = dt.minute;
        final period = h < 12 ? '오전' : '오후';
        final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
        return '$period ${displayH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
      }
      if (diff.inDays < 7) return '${diff.inDays}일 전';
      return '${dt.month}월 ${dt.day}일';
    } catch (_) {
      return '방금 전';
    }
  }

  Map<String, dynamic> _mapMessageRow(Map<String, dynamic> row, String myId) {
    final profiles = row['profiles'] as Map<String, dynamic>?;
    final nickname = (profiles?['nickname'] as String?)?.isNotEmpty == true
        ? profiles!['nickname'] as String
        : (profiles?['username'] as String? ?? 'Unknown');
    final senderId = row['sender_id'] as String? ?? '';
    return {
      'id': (row['id'] as String).hashCode.abs(),
      'supabaseId': row['id'] as String?,
      'text': row['content'] as String? ?? '',
      'isMe': senderId == myId,
      'senderName': nickname,
      'timestamp': _formatTimestamp(row['created_at'] as String?),
      'type': 'text',
    };
  }

  // ---------------------------------------------------------------------------
  // 공개 API
  // ---------------------------------------------------------------------------

  /// 내 채팅방 목록 → UI용 항목 리스트
  Future<List<Map<String, dynamic>>> getConversations() async {
    final myId = SupabaseService.instance.currentUser?.id;
    if (myId == null) return [];
    try {
      final rooms = await SupabaseService.instance.getMyChatRooms(myId);
      final result = <Map<String, dynamic>>[];
      for (final room in rooms) {
        final member = room['member'] as Map<String, dynamic>?;
        final profiles = member?['profiles'] as Map<String, dynamic>?;
        final nickname = (profiles?['nickname'] as String?)?.isNotEmpty == true
            ? profiles!['nickname'] as String
            : (profiles?['username'] as String? ?? 'Unknown');
        final avatarUrl = profiles?['avatar_url'] as String?;
        final otherUserId = member?['user_id'] as String?;
        final lastMsg = room['lastMessage'] as Map<String, dynamic>?;
        final lastContent = lastMsg?['content'] as String? ?? '';
        final lastTime = _formatTimestamp(lastMsg?['created_at'] as String?);
        result.add({
          'id': (room['roomId'] as String).hashCode.abs(),
          'roomId': room['roomId'] as String,
          'otherUserId': otherUserId,
          'userName': nickname,
          'userAvatar': avatarUrl ?? '👤',
          'lastMessage': lastContent,
          'timestamp': lastTime,
          'unreadCount': 0,
          'isOnline': false,
          'lastMessageType': 'text',
          'isTyping': false,
          'lastSeen': lastTime,
          'muted': false,
          'pinned': false,
        });
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  /// 채팅방 열기 (없으면 생성), 실패 시 null 반환
  Future<String?> getOrOpenRoom(String otherUserId) async {
    final myId = SupabaseService.instance.currentUser?.id;
    if (myId == null) return null;
    try {
      return await SupabaseService.instance.getOrCreateDmRoom(myId, otherUserId);
    } catch (_) {
      return null;
    }
  }

  /// 채팅방 메시지 로드
  Future<List<Map<String, dynamic>>> loadMessages(String roomId) async {
    final myId = SupabaseService.instance.currentUser?.id ?? '';
    try {
      final rows = await SupabaseService.instance.getRoomMessages(roomId);
      return rows.map((r) => _mapMessageRow(r, myId)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 메시지 전송 (비동기 fire-and-forget)
  void sendMessage(String roomId, String content) {
    final myId = SupabaseService.instance.currentUser?.id;
    if (myId == null) return;
    SupabaseService.instance.sendChatMessage(
      roomId: roomId,
      senderId: myId,
      content: content,
    ).catchError((_) => null);
  }

  /// 실시간 구독 (내가 보낸 메시지 중복 제외)
  void subscribeToRoom(
    String roomId,
    void Function(Map<String, dynamic> message) onMessage,
  ) {
    unsubscribeFromRoom(roomId);
    final myId = SupabaseService.instance.currentUser?.id ?? '';
    final channel = SupabaseService.instance.subscribeToRoomMessages(
      roomId,
      (payload) {
        final senderId = payload['sender_id'] as String? ?? '';
        // 내가 보낸 메시지는 이미 로컬에 추가됨 → 스킵
        if (senderId == myId) return;
        onMessage({
          'id': DateTime.now().millisecondsSinceEpoch,
          'text': payload['content'] as String? ?? '',
          'isMe': false,
          'senderName': 'Unknown',
          'timestamp': _formatTimestamp(payload['created_at'] as String?),
          'type': 'text',
        });
      },
    );
    _subscriptions[roomId] = channel;
  }

  /// 실시간 구독 해제
  void unsubscribeFromRoom(String roomId) {
    final channel = _subscriptions.remove(roomId);
    if (channel != null) {
      SupabaseService.instance.unsubscribeFromChannel(channel).catchError((_) {});
    }
  }
}
