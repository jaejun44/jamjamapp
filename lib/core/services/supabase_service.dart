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
} 