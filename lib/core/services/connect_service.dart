import 'package:jamjamapp/core/services/supabase_service.dart';

/// Connect(매칭) 비즈니스 로직 서비스
/// Supabase connect_likes / matches 테이블 연동 담당
class ConnectService {
  static final ConnectService _instance = ConnectService._internal();
  static ConnectService get instance => _instance;
  ConnectService._internal();

  // ---------------------------------------------------------------------------
  // 내부 유틸
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _mapProfileRow(Map<String, dynamic> row) {
    return {
      'userId': row['id'] as String? ?? '',
      'username': row['username'] as String? ?? '',
      'nickname': (row['nickname'] as String?)?.isNotEmpty == true
          ? row['nickname'] as String
          : (row['username'] as String? ?? 'Unknown'),
      'avatarUrl': row['avatar_url'] as String?,
    };
  }

  Map<String, dynamic> _mapMatchRow(
      Map<String, dynamic> row, String myId) {
    // 내가 user1 이면 상대는 user2, 그 반대도 동일
    final isUser1 = (row['user1'] as Map<String, dynamic>?)?['id'] == myId;
    final other = isUser1
        ? row['user2'] as Map<String, dynamic>?
        : row['user1'] as Map<String, dynamic>?;
    return {
      'matchId': row['id'] as String? ?? '',
      'matchedAt': row['created_at'] as String?,
      'userId': other?['id'] as String? ?? '',
      'username': other?['username'] as String? ?? '',
      'nickname': (other?['nickname'] as String?)?.isNotEmpty == true
          ? other!['nickname'] as String
          : (other?['username'] as String? ?? 'Unknown'),
      'avatarUrl': other?['avatar_url'] as String?,
    };
  }

  // ---------------------------------------------------------------------------
  // 공개 API
  // ---------------------------------------------------------------------------

  /// 추천 유저 목록 (이미 좋아요 누른 유저 제외)
  Future<List<Map<String, dynamic>>> getCandidates() async {
    try {
      final rows = await SupabaseService.instance.getCandidates();
      return rows.map(_mapProfileRow).toList();
    } catch (_) {
      return [];
    }
  }

  /// 좋아요 → 매칭 여부 반환
  /// true: 매칭 성사, false: 아직 단방향
  Future<bool> like(String toId) async {
    try {
      await SupabaseService.instance.likeUser(toId);
      final myId = SupabaseService.instance.currentUser?.id;
      if (myId == null) return false;
      final mutual = await SupabaseService.instance.checkMutualLike(myId, toId);
      if (mutual) {
        await SupabaseService.instance.createMatch(myId, toId);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 좋아요 취소
  Future<void> pass(String toId) async {
    try {
      await SupabaseService.instance.unlikeUser(toId);
    } catch (_) {}
  }

  /// 내 매치 목록
  Future<List<Map<String, dynamic>>> getMatches() async {
    final myId = SupabaseService.instance.currentUser?.id;
    if (myId == null) return [];
    try {
      final rows = await SupabaseService.instance.getMatches(myId);
      return rows.map((r) => _mapMatchRow(r, myId)).toList();
    } catch (_) {
      return [];
    }
  }
}
