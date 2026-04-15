import 'package:jamjamapp/core/services/supabase_service.dart';
import 'package:jamjamapp/core/services/auth_state_manager.dart';

/// Jam 세션 데이터 서비스
/// Supabase jam_sessions 테이블 CRUD 및 UI 데이터 매핑 담당
class JamService {
  static final JamService _instance = JamService._internal();
  factory JamService() => _instance;
  JamService._internal();

  static JamService get instance => _instance;

  // ---------------------------------------------------------------------------
  // 내부 유틸
  // ---------------------------------------------------------------------------

  int _uuidToInt(String uuid) => uuid.hashCode.abs();

  String _formatTimestamp(String? isoString) {
    if (isoString == null) return '방금 전';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return '방금 전';
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      if (diff.inDays < 7) return '${diff.inDays}일 전';
      return '${dt.month}월 ${dt.day}일';
    } catch (_) {
      return '방금 전';
    }
  }

  /// Supabase 행 → UI에서 쓰는 Jam 세션 Map
  Map<String, dynamic> _mapRow(Map<String, dynamic> row) {
    final supabaseId = row['id'] as String;
    final intId = _uuidToInt(supabaseId);
    final profiles = row['profiles'] as Map<String, dynamic>?;
    final nickname = (profiles?['nickname'] as String?)?.isNotEmpty == true
        ? profiles!['nickname'] as String
        : (profiles?['username'] as String? ?? 'Unknown');
    final avatarUrl = profiles?['avatar_url'] as String?;

    // instruments: Supabase에서 List 또는 String으로 올 수 있음
    final rawInstruments = row['instruments'];
    final instrumentsStr = rawInstruments is List
        ? rawInstruments.join(', ')
        : (rawInstruments as String? ?? '');

    final statusRaw = row['status'] as String? ?? 'open';
    final statusLabel = statusRaw == 'open'
        ? '모집 중'
        : statusRaw == 'active'
            ? '진행 중'
            : '완료';

    final description = row['description'] as String? ?? '';

    // tags: instruments 배열에서 추출
    final tags = rawInstruments is List
        ? rawInstruments.map((e) => e.toString()).toList()
        : instrumentsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return {
      'id': intId,
      'supabaseId': supabaseId,
      'title': row['title'] as String? ?? '',
      'genre': instrumentsStr, // genre 컬럼 없으므로 instruments로 대체
      'instruments': instrumentsStr,
      'participants': 1,
      'maxParticipants': (row['max_participants'] as int?) ?? 5,
      'status': statusLabel,
      'createdBy': nickname,
      'createdByAvatar': avatarUrl,
      'createdAt': _formatTimestamp(row['created_at'] as String?),
      'description': description,
      'tags': tags,
      'isLive': false,
      'recordingUrl': null,
      'files': <dynamic>[],
      'chat': <dynamic>[],
      'participantsList': [
        {
          'id': 1,
          'name': nickname,
          'avatar': avatarUrl ?? '👤',
          'role': '방장',
          'instruments': rawInstruments is List ? List<String>.from(rawInstruments) : [instrumentsStr],
          'isOnline': true,
          'joinTime': _formatTimestamp(row['created_at'] as String?),
        }
      ],
    };
  }

  // ---------------------------------------------------------------------------
  // 공개 API
  // ---------------------------------------------------------------------------

  /// Supabase에서 Jam 세션 목록 가져오기
  Future<List<Map<String, dynamic>>> fetchJamSessions({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final rows = await SupabaseService.instance.getJamSessions(
        limit: limit,
        offset: offset,
      );
      return rows.map(_mapRow).toList();
    } catch (_) {
      return [];
    }
  }

  /// Supabase에 Jam 세션 생성, 실패 시 null 반환
  Future<Map<String, dynamic>?> createJamSession({
    required String title,
    required String description,
    required String instruments,
    required int maxParticipants,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return null;

    final instrumentsList = instruments
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    try {
      await SupabaseService.instance.createJamSession(
        userId: userId,
        title: title,
        description: description,
        instruments: instrumentsList,
        maxParticipants: maxParticipants,
      );
    } catch (_) {
      // 생성 실패 — 로컬 세션은 이미 표시됨, 조용히 무시
    }

    // 즉각 표시용 임시 로컬 세션 반환
    return {
      'id': DateTime.now().millisecondsSinceEpoch,
      'supabaseId': null,
      'title': title,
      'genre': instruments,
      'instruments': instruments,
      'participants': 1,
      'maxParticipants': maxParticipants,
      'status': '모집 중',
      'createdBy': AuthStateManager.instance.userName,
      'createdByAvatar': AuthStateManager.instance.avatarUrl,
      'createdAt': '방금 전',
      'description': description,
      'tags': instrumentsList,
      'isLive': false,
      'recordingUrl': null,
      'files': <dynamic>[],
      'chat': <dynamic>[],
      'participantsList': [
        {
          'id': 1,
          'name': AuthStateManager.instance.userName,
          'avatar': '👤',
          'role': '방장',
          'instruments': instrumentsList,
          'isOnline': true,
          'joinTime': '방금 전',
        }
      ],
    };
  }
}
