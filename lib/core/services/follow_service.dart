import 'package:jamjamapp/core/services/supabase_service.dart';

/// 팔로우(Watch) 비즈니스 로직 서비스
/// Supabase follows 테이블 연동 담당
class FollowService {
  static final FollowService _instance = FollowService._internal();
  static FollowService get instance => _instance;
  FollowService._internal();

  // ---------------------------------------------------------------------------
  // 내부 유틸
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _mapProfileRow(Map<String, dynamic> row, String profileKey) {
    final profiles = row[profileKey] as Map<String, dynamic>?;
    final nickname = (profiles?['nickname'] as String?)?.isNotEmpty == true
        ? profiles!['nickname'] as String
        : (profiles?['username'] as String? ?? 'Unknown');
    return {
      'userId': profiles?['id'] as String? ?? '',
      'username': profiles?['username'] as String? ?? '',
      'nickname': nickname,
      'avatarUrl': profiles?['avatar_url'] as String?,
    };
  }

  // ---------------------------------------------------------------------------
  // 공개 API
  // ---------------------------------------------------------------------------

  /// 팔로우 여부 확인
  Future<bool> isFollowing(String targetUserId) async {
    final myId = SupabaseService.instance.currentUser?.id;
    if (myId == null) return false;
    try {
      return await SupabaseService.instance.isFollowing(myId, targetUserId);
    } catch (_) {
      return false;
    }
  }

  /// 팔로우 (이미 팔로우 중이면 무시)
  Future<bool> follow(String targetUserId) async {
    try {
      await SupabaseService.instance.follow(targetUserId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 언팔로우
  Future<bool> unfollow(String targetUserId) async {
    try {
      await SupabaseService.instance.unfollow(targetUserId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 팔로우 토글 — 현재 상태 반환
  Future<bool> toggleFollow(String targetUserId) async {
    final already = await isFollowing(targetUserId);
    if (already) {
      await unfollow(targetUserId);
      return false;
    } else {
      await follow(targetUserId);
      return true;
    }
  }

  /// 내가 팔로우하는 사람 목록
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      final rows = await SupabaseService.instance.getFollowing(userId);
      return rows.map((r) => _mapProfileRow(r, 'profiles')).toList();
    } catch (_) {
      return [];
    }
  }

  /// 나를 팔로우하는 사람 목록
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      final rows = await SupabaseService.instance.getFollowers(userId);
      return rows.map((r) => _mapProfileRow(r, 'profiles')).toList();
    } catch (_) {
      return [];
    }
  }

  /// 팔로잉/팔로워 수 동시 조회
  Future<({int following, int followers})> getCounts(String userId) async {
    try {
      final results = await Future.wait([
        SupabaseService.instance.getFollowingCount(userId),
        SupabaseService.instance.getFollowerCount(userId),
      ]);
      return (following: results[0], followers: results[1]);
    } catch (_) {
      return (following: 0, followers: 0);
    }
  }
}
