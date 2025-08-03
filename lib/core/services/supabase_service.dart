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
    // 환경 변수 로드 시도 (실패해도 계속 진행)
    try {
      await dotenv.load(fileName: "assets/.env");
    } catch (e) {
      print('환경 변수 로드 실패, 하드코딩된 값 사용: $e');
    }
    
    // 하드코딩된 Supabase 설정
    const supabaseUrl = 'https://aadlqmyynidfsygnxnnk.supabase.co';
    const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFhZGxxbXl5bmlkZnN5Z254bm5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyNDIwMjUsImV4cCI6MjA2OTgxODAyNX0.6ymus7BN145eQsKHSOBwajuCq17fjIEd7Hf0fpTZ-8Y';
    
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
        .single();
    
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
} 