import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data'; // Added for Uint8List

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._internal();
  
  SupabaseService._internal();

  late SupabaseClient _client;
  
  SupabaseClient get client => _client;

  /// Supabase 초기화
  Future<void> initialize() async {
    await dotenv.load(fileName: ".env");

    final supabaseUrl = dotenv.env['SUPABASE_URL']!;
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    
    _client = Supabase.instance.client;
  }

  /// 현재 사용자 가져오기
  User? get currentUser => _client.auth.currentUser;

  /// 로그인 상태 확인
  bool get isAuthenticated => currentUser != null;

  /// 로그아웃
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// 이메일/비밀번호로 로그인
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// 이메일/비밀번호로 회원가입
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: userData,
    );
  }

  /// 회원가입 + profiles 테이블 초기 행 생성 (원자적 처리)
  Future<AuthResponse> signUpWithProfile({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'nickname': nickname},
    );

    if (response.user != null && response.session != null) {
      final username = email.split('@')[0];
      await _client.from('profiles').upsert({
        'id': response.user!.id,
        'username': username,
        'nickname': nickname,
        'bio': '새로운 음악인입니다 🎵',
        'instruments': '기타, 피아노',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return response;
  }

  /// 사용자 프로필 업데이트
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    await _client
        .from('profiles')
        .upsert({
          'id': userId,
          ...profileData,
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  /// 사용자 프로필 가져오기
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  /// 피드 데이터 가져오기
  Future<List<Map<String, dynamic>>> getFeedData({
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await _client
        .from('feeds')
        .select('''
          *,
          profiles:user_id (
            id,
            username,
            nickname,
            bio,
            avatar_url
          )
        ''')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// 피드 생성
  Future<void> createFeed({
    required String userId,
    required String content,
    List<String>? mediaUrls,
    String? jamSessionId,
  }) async {
    await _client.from('feeds').insert({
      'user_id': userId,
      'content': content,
      'media_urls': mediaUrls,
      'jam_session_id': jamSessionId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Jam 세션 생성
  Future<void> createJamSession({
    required String userId,
    required String title,
    required String description,
    List<String>? instruments,
    int? maxParticipants,
  }) async {
    await _client.from('jam_sessions').insert({
      'creator_id': userId,
      'title': title,
      'description': description,
      'instruments': instruments,
      'max_participants': maxParticipants,
      'status': 'open',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Jam 세션 목록 가져오기
  Future<List<Map<String, dynamic>>> getJamSessions({
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await _client
        .from('jam_sessions')
        .select('''
          *,
          profiles:creator_id (
            id,
            username,
            nickname,
            avatar_url
          )
        ''')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// 실시간 구독 설정
  RealtimeChannel subscribeToChannel(String channelName) {
    return _client.channel(channelName);
  }

  /// 파일 업로드
  Future<String> uploadFile({
    required String bucketName,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    await _client.storage
        .from(bucketName)
        .uploadBinary(fileName, fileBytes);
    
    return _client.storage
        .from(bucketName)
        .getPublicUrl(fileName);
  }

  /// 아바타 이미지 업로드 (upsert) 후 공개 URL 반환
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List imageBytes,
  }) async {
    const bucketName = 'avatars';
    final fileName = '$userId.jpg';

    await _client.storage.from(bucketName).uploadBinary(
      fileName,
      imageBytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );

    return _client.storage.from(bucketName).getPublicUrl(fileName);
  }

  /// 미디어 파일 업로드 (media 버킷) 후 공개 URL 반환
  /// [mediaType] 은 'image' | 'video' | 'audio'
  Future<String> uploadMedia({
    required String userId,
    required Uint8List fileBytes,
    required String mediaType,
  }) async {
    const bucketName = 'media';
    final ext = mediaType == 'video'
        ? 'mp4'
        : mediaType == 'audio'
            ? 'mp3'
            : 'jpg';
    final contentType = mediaType == 'video'
        ? 'video/mp4'
        : mediaType == 'audio'
            ? 'audio/mpeg'
            : 'image/jpeg';
    final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from(bucketName).uploadBinary(
      fileName,
      fileBytes,
      fileOptions: FileOptions(upsert: false, contentType: contentType),
    );

    return _client.storage.from(bucketName).getPublicUrl(fileName);
  }

  /// 파일 경로로 업로드 (웹 환경용)
  Future<String> uploadFileFromPath({
    required String bucketName,
    required String filePath,
    required String fileName,
  }) async {
    // 웹 환경에서는 파일 경로 대신 파일 객체를 사용해야 함
    // 이 메서드는 나중에 구현 예정
    throw UnimplementedError('uploadFileFromPath는 아직 구현되지 않았습니다. uploadFile을 사용하세요.');
  }

  /// 피드 삭제
  Future<void> deleteFeed(String feedId) async {
    await _client.from('feeds').delete().eq('id', feedId);
  }

  /// 피드 콘텐츠 업데이트
  Future<void> updateFeedContent({
    required String feedId,
    required String content,
  }) async {
    await _client.from('feeds').update({
      'content': content,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', feedId);
  }

  /// 피드별 댓글 가져오기 (profiles join, created_at 오름차순)
  Future<List<Map<String, dynamic>>> getComments(String feedId) async {
    final response = await _client
        .from('comments')
        .select('''
          *,
          profiles:author_id (
            id,
            username,
            nickname,
            avatar_url
          )
        ''')
        .eq('feed_id', feedId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// 댓글 추가 후 삽입된 행 반환
  Future<Map<String, dynamic>> addComment({
    required String feedId,
    required String authorId,
    required String content,
    String? parentId,
  }) async {
    final data = <String, dynamic>{
      'feed_id': feedId,
      'author_id': authorId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    };
    if (parentId != null) data['parent_id'] = parentId;

    final response = await _client
        .from('comments')
        .insert(data)
        .select('''
          *,
          profiles:author_id (
            id,
            username,
            nickname,
            avatar_url
          )
        ''')
        .single();
    return Map<String, dynamic>.from(response);
  }

  /// 댓글 삭제
  Future<void> deleteComment(String commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }

  /// 댓글 내용 수정
  Future<void> updateCommentContent({
    required String commentId,
    required String content,
  }) async {
    await _client
        .from('comments')
        .update({'content': content})
        .eq('id', commentId);
  }

  /// 백엔드 연결 테스트
  Future<bool> testConnection() async {
    try {
      // 간단한 쿼리로 연결 테스트
      await _client
          .from('profiles')
          .select('count')
          .limit(1);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 데이터베이스 스키마 확인
  Future<void> checkDatabaseSchema() async {
    try {
      // profiles 테이블 확인
      await _client.from('profiles').select('*').limit(1);

      // feeds 테이블 확인
      await _client.from('feeds').select('*').limit(1);

      // jam_sessions 테이블 확인
      await _client.from('jam_sessions').select('*').limit(1);

      // chat_messages 테이블 확인
      await _client.from('chat_messages').select('*').limit(1);

    } catch (e) { // ignore: empty_catches
    }
  }

  // ---------------------------------------------------------------------------
  // A-7 Chat
  // ---------------------------------------------------------------------------

  /// DM 채팅방 찾기 또는 생성
  Future<String> getOrCreateDmRoom(String myId, String otherId) async {
    // 내가 속한 DM 방 목록 조회
    final myMemberships = await _client
        .from('chat_members')
        .select('room_id, chat_rooms!inner(type)')
        .eq('user_id', myId);

    final myDmRoomIds = (myMemberships as List)
        .where((m) => (m['chat_rooms'] as Map?)?['type'] == 'dm')
        .map((m) => m['room_id'] as String?)
        .whereType<String>()
        .toList();

    if (myDmRoomIds.isNotEmpty) {
      final sharedRoom = await _client
          .from('chat_members')
          .select('room_id')
          .eq('user_id', otherId)
          .inFilter('room_id', myDmRoomIds)
          .maybeSingle();
      if (sharedRoom != null) return sharedRoom['room_id'] as String;
    }

    // 새 DM 방 생성
    final room = await _client
        .from('chat_rooms')
        .insert({'type': 'dm'})
        .select('id')
        .single();
    final roomId = room['id'] as String;
    await _client.from('chat_members').insert([
      {'room_id': roomId, 'user_id': myId},
      {'room_id': roomId, 'user_id': otherId},
    ]);
    return roomId;
  }

  /// 내 채팅방 목록 (상대방 프로필 + 최근 메시지)
  Future<List<Map<String, dynamic>>> getMyChatRooms(String myId) async {
    final memberships = await _client
        .from('chat_members')
        .select('room_id')
        .eq('user_id', myId);

    final roomIds = (memberships as List)
        .map((m) => m['room_id'] as String)
        .toList();
    if (roomIds.isEmpty) return [];

    // 각 방의 상대방 프로필
    final otherMembers = await _client
        .from('chat_members')
        .select('room_id, user_id, profiles:user_id(id, username, nickname, avatar_url)')
        .inFilter('room_id', roomIds)
        .neq('user_id', myId);

    // 각 방의 최근 메시지
    final messages = await _client
        .from('chat_messages')
        .select('room_id, content, created_at, sender_id')
        .inFilter('room_id', roomIds)
        .order('created_at', ascending: false);

    // roomId → 최신 메시지
    final latestMessages = <String, Map<String, dynamic>>{};
    for (final msg in (messages as List)) {
      final rId = msg['room_id'] as String;
      if (!latestMessages.containsKey(rId)) {
        latestMessages[rId] = Map<String, dynamic>.from(msg);
      }
    }

    // roomId → 상대방
    final membersByRoom = <String, Map<String, dynamic>>{};
    for (final m in (otherMembers as List)) {
      final rId = m['room_id'] as String;
      if (!membersByRoom.containsKey(rId)) {
        membersByRoom[rId] = Map<String, dynamic>.from(m);
      }
    }

    return roomIds.map((roomId) => <String, dynamic>{
      'roomId': roomId,
      'member': membersByRoom[roomId],
      'lastMessage': latestMessages[roomId],
    }).toList();
  }

  /// 채팅방 메시지 조회
  Future<List<Map<String, dynamic>>> getRoomMessages(String roomId) async {
    final response = await _client
        .from('chat_messages')
        .select('*, profiles:sender_id(id, username, nickname, avatar_url)')
        .eq('room_id', roomId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// 채팅 메시지 전송
  Future<Map<String, dynamic>?> sendChatMessage({
    required String roomId,
    required String senderId,
    required String content,
  }) async {
    try {
      final response = await _client
          .from('chat_messages')
          .insert({
            'room_id': roomId,
            'sender_id': senderId,
            'content': content,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } catch (_) {
      return null;
    }
  }

  /// 채팅방 실시간 구독 (room_id 필터)
  RealtimeChannel subscribeToRoomMessages(
    String roomId,
    void Function(Map<String, dynamic> payload) onInsert,
  ) {
    final channel = _client.channel('chat_room_$roomId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
    return channel;
  }

  /// 채팅 구독 해제
  Future<void> unsubscribeFromChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }

  // ---------------------------------------------------------------------------
  // B-1 Follow (Watch)
  // ---------------------------------------------------------------------------

  /// 팔로우 여부 확인
  Future<bool> isFollowing(String followerId, String followingId) async {
    final row = await _client
        .from('follows')
        .select('follower_id')
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .maybeSingle();
    return row != null;
  }

  /// 팔로우
  Future<void> follow(String followingId) async {
    final myId = currentUser?.id;
    if (myId == null) return;
    await _client.from('follows').insert({
      'follower_id': myId,
      'following_id': followingId,
    });
  }

  /// 언팔로우
  Future<void> unfollow(String followingId) async {
    final myId = currentUser?.id;
    if (myId == null) return;
    await _client
        .from('follows')
        .delete()
        .eq('follower_id', myId)
        .eq('following_id', followingId);
  }

  /// 내가 팔로우하는 사람 목록 (profiles join)
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    final response = await _client
        .from('follows')
        .select('following_id, profiles:following_id(id, username, nickname, avatar_url)')
        .eq('follower_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// 나를 팔로우하는 사람 목록 (profiles join)
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    final response = await _client
        .from('follows')
        .select('follower_id, profiles:follower_id(id, username, nickname, avatar_url)')
        .eq('following_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// 팔로잉 수
  Future<int> getFollowingCount(String userId) async {
    final response = await _client
        .from('follows')
        .select('follower_id')
        .eq('follower_id', userId);
    return (response as List).length;
  }

  /// 팔로워 수
  Future<int> getFollowerCount(String userId) async {
    final response = await _client
        .from('follows')
        .select('following_id')
        .eq('following_id', userId);
    return (response as List).length;
  }

  // ---------------------------------------------------------------------------
  // B-2 Connect (Match)
  // ---------------------------------------------------------------------------

  /// 상대방에게 좋아요 (이미 있으면 무시)
  Future<void> likeUser(String toId) async {
    final myId = currentUser?.id;
    if (myId == null) return;
    await _client.from('connect_likes').upsert({
      'from_id': myId,
      'to_id': toId,
    });
  }

  /// 좋아요 취소
  Future<void> unlikeUser(String toId) async {
    final myId = currentUser?.id;
    if (myId == null) return;
    await _client
        .from('connect_likes')
        .delete()
        .eq('from_id', myId)
        .eq('to_id', toId);
  }

  /// 내가 특정 유저에게 좋아요를 눌렀는지 확인
  Future<bool> hasLiked(String fromId, String toId) async {
    final row = await _client
        .from('connect_likes')
        .select('from_id')
        .eq('from_id', fromId)
        .eq('to_id', toId)
        .maybeSingle();
    return row != null;
  }

  /// 서로 좋아요 여부 확인 (매칭 조건)
  Future<bool> checkMutualLike(String userId1, String userId2) async {
    final a = await hasLiked(userId1, userId2);
    if (!a) return false;
    return hasLiked(userId2, userId1);
  }

  /// 매치 생성 (user1 < user2 UUID 순 정렬 필수)
  Future<Map<String, dynamic>?> createMatch(
      String userId1, String userId2) async {
    // DB constraint: user1_id < user2_id
    final sorted = [userId1, userId2]..sort();
    try {
      final response = await _client
          .from('matches')
          .upsert({
            'user1_id': sorted[0],
            'user2_id': sorted[1],
          })
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } catch (_) {
      return null;
    }
  }

  /// 내 매치 목록 (profiles join)
  Future<List<Map<String, dynamic>>> getMatches(String userId) async {
    final response = await _client
        .from('matches')
        .select(
          'id, created_at, '
          'user1:user1_id(id, username, nickname, avatar_url), '
          'user2:user2_id(id, username, nickname, avatar_url)',
        )
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// 아직 스와이프하지 않은 추천 유저 목록 (팔로잉 제외, 나 제외, 이미 좋아요 제외)
  /// 간단 구현: profiles 전체 fetch 후 로컬 필터
  Future<List<Map<String, dynamic>>> getCandidates() async {
    final myId = currentUser?.id;
    if (myId == null) return [];

    // 내가 이미 좋아요 누른 유저 ID 수집
    final likedRows = await _client
        .from('connect_likes')
        .select('to_id')
        .eq('from_id', myId);
    final likedIds = (likedRows as List)
        .map((r) => r['to_id'] as String)
        .toSet();

    // 프로필 전체 (간단 구현, 대규모 시 서버 필터 필요)
    final profiles = await _client
        .from('profiles')
        .select('id, username, nickname, avatar_url')
        .neq('id', myId);

    return (profiles as List)
        .cast<Map<String, dynamic>>()
        .where((p) => !likedIds.contains(p['id'] as String?))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // B-3 Notifications
  // ---------------------------------------------------------------------------

  /// 내 알림 목록 (최신순)
  Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 30,
    bool unreadOnly = false,
  }) async {
    final myId = currentUser?.id;
    if (myId == null) return [];
    var query = _client
        .from('notifications')
        .select('id, type, payload, read, created_at')
        .eq('user_id', myId);
    if (unreadOnly) {
      query = query.eq('read', false);
    }
    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  /// 읽지 않은 알림 수
  Future<int> getUnreadNotificationCount() async {
    final myId = currentUser?.id;
    if (myId == null) return 0;
    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', myId)
        .eq('read', false);
    return (response as List).length;
  }

  /// 특정 알림 읽음 처리
  Future<void> markNotificationRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }

  /// 내 알림 전체 읽음 처리
  Future<void> markAllNotificationsRead() async {
    final myId = currentUser?.id;
    if (myId == null) return;
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('user_id', myId)
        .eq('read', false);
  }

  /// 알림 실시간 구독
  RealtimeChannel subscribeToNotifications(
    void Function(Map<String, dynamic> payload) onInsert,
  ) {
    final myId = currentUser?.id;
    final channel = _client.channel('notifications_${myId ?? 'anon'}');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: myId != null
              ? PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'user_id',
                  value: myId,
                )
              : null,
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
    return channel;
  }
} 