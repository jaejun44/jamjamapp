import 'dart:math';

/// 고급 검색 알고리즘과 성능 최적화를 위한 유틸리티 클래스
class SearchUtils {
  
  /// Levenshtein 거리 계산 (유사도 검색)
  static int levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        int cost = s1[i] == s2[j] ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }

      List<int> temp = v0;
      v0 = v1;
      v1 = temp;
    }

    return v0[s2.length];
  }

  /// Jaro-Winkler 유사도 계산
  static double jaroWinklerSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    int matchDistance = (max(s1.length, s2.length) / 2 - 1).floor();
    if (matchDistance < 0) matchDistance = 0;

    List<bool> s1Matches = List<bool>.filled(s1.length, false);
    List<bool> s2Matches = List<bool>.filled(s2.length, false);

    int matches = 0;
    int transpositions = 0;

    // 첫 번째 패스: 매치 찾기
    for (int i = 0; i < s1.length; i++) {
      int start = max(0, i - matchDistance);
      int end = min(i + matchDistance + 1, s2.length);

      for (int j = start; j < end; j++) {
        if (s2Matches[j] || s1[i] != s2[j]) continue;
        s1Matches[i] = true;
        s2Matches[j] = true;
        matches++;
        break;
      }
    }

    if (matches == 0) return 0.0;

    // 두 번째 패스: 전치 찾기
    int k = 0;
    for (int i = 0; i < s1.length; i++) {
      if (!s1Matches[i]) continue;
      while (!s2Matches[k]) k++;
      if (s1[i] != s2[k]) transpositions++;
      k++;
    }

    double jaro = (matches / s1.length + matches / s2.length + (matches - transpositions / 2) / matches) / 3;

    // Winkler 수정
    int prefixLength = 0;
    for (int i = 0; i < min(4, min(s1.length, s2.length)); i++) {
      if (s1[i] == s2[i]) {
        prefixLength++;
      } else {
        break;
      }
    }

    return jaro + (prefixLength * 0.1 * (1 - jaro));
  }

  /// 태그 기반 가중치 검색 점수 계산
  static double calculateTagScore(Map<String, dynamic> musician, String query, List<String> searchTerms) {
    double score = 0.0;
    String queryLower = query.toLowerCase();
    
    // 이름 매칭 (가장 높은 가중치)
    if (musician['name'].toLowerCase().contains(queryLower)) {
      score += 10.0;
    }
    
    // 장르 매칭
    if (musician['genre'].toLowerCase().contains(queryLower)) {
      score += 8.0;
    }
    
    // 악기 매칭
    if (musician['instrument'].toLowerCase().contains(queryLower)) {
      score += 7.0;
    }
    
    // 지역 매칭
    if (musician['location'].toLowerCase().contains(queryLower)) {
      score += 6.0;
    }
    
    // 소개 매칭
    if (musician['bio'].toLowerCase().contains(queryLower)) {
      score += 5.0;
    }
    
    // 태그 매칭 (복합 검색)
    for (String tag in musician['tags']) {
      if (tag.toLowerCase().contains(queryLower)) {
        score += 4.0;
      }
    }
    
    // 유사도 검색 (정확한 매칭이 없을 때)
    if (score == 0) {
      double nameSimilarity = jaroWinklerSimilarity(musician['name'].toLowerCase(), queryLower);
      double genreSimilarity = jaroWinklerSimilarity(musician['genre'].toLowerCase(), queryLower);
      double instrumentSimilarity = jaroWinklerSimilarity(musician['instrument'].toLowerCase(), queryLower);
      
      score = (nameSimilarity * 3 + genreSimilarity * 2 + instrumentSimilarity * 2) / 7;
    }
    
    // 팔로워 수 보너스 (인기도 반영)
    score += (musician['followers'] / 10000) * 0.5;
    
    // 온라인 상태 보너스
    if (musician['isOnline']) {
      score += 0.5;
    }
    
    // 인증 상태 보너스
    if (musician['verified']) {
      score += 0.3;
    }
    
    return score;
  }

  /// 검색어 토큰화 (복합 검색 지원)
  static List<String> tokenizeQuery(String query) {
    return query
        .toLowerCase()
        .split(RegExp(r'[\s,]+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  /// 검색 제안 생성
  static List<String> generateSearchSuggestions(String partialQuery, List<Map<String, dynamic>> musicians) {
    if (partialQuery.isEmpty) return [];
    
    Set<String> suggestions = {};
    String queryLower = partialQuery.toLowerCase();
    
    // 이름에서 제안
    for (var musician in musicians) {
      String name = musician['name'];
      if (name.toLowerCase().startsWith(queryLower)) {
        suggestions.add(name);
      }
    }
    
    // 장르에서 제안
    for (var musician in musicians) {
      String genre = musician['genre'];
      if (genre.toLowerCase().startsWith(queryLower)) {
        suggestions.add(genre);
      }
    }
    
    // 악기에서 제안
    for (var musician in musicians) {
      String instrument = musician['instrument'];
      if (instrument.toLowerCase().startsWith(queryLower)) {
        suggestions.add(instrument);
      }
    }
    
    // 태그에서 제안
    for (var musician in musicians) {
      for (String tag in musician['tags']) {
        if (tag.toLowerCase().startsWith(queryLower)) {
          suggestions.add(tag);
        }
      }
    }
    
    return suggestions.take(10).toList();
  }

  /// 검색 결과 캐싱을 위한 키 생성
  static String generateCacheKey(String query, Set<String> genres, Set<String> instruments, Set<String> locations, String sortBy, String sortOrder) {
    List<String> parts = [
      query,
      genres.join(','),
      instruments.join(','),
      locations.join(','),
      sortBy,
      sortOrder,
    ];
    return parts.join('|');
  }

  /// 검색 결과 정렬 (다중 기준)
  static List<Map<String, dynamic>> sortSearchResults(
    List<Map<String, dynamic>> results,
    String sortBy,
    String sortOrder,
    String query,
  ) {
    results.sort((a, b) {
      int comparison = 0;
      
      switch (sortBy) {
        case 'relevance':
          // 검색 관련성 기준 정렬
          double scoreA = calculateTagScore(a, query, tokenizeQuery(query));
          double scoreB = calculateTagScore(b, query, tokenizeQuery(query));
          comparison = scoreB.compareTo(scoreA); // 높은 점수 먼저
          break;
          
        case 'name':
          comparison = a['name'].compareTo(b['name']);
          break;
          
        case 'followers':
          comparison = a['followers'].compareTo(b['followers']);
          break;
          
        case 'recent':
          comparison = a['lastActive'].compareTo(b['lastActive']);
          break;
          
        case 'posts':
          comparison = a['posts'].compareTo(b['posts']);
          break;
          
        default:
          comparison = a['name'].compareTo(b['name']);
      }
      
      return sortOrder == 'asc' ? comparison : -comparison;
    });
    
    return results;
  }

  /// 검색 결과 필터링 (고급 필터링)
  static List<Map<String, dynamic>> filterSearchResults(
    List<Map<String, dynamic>> results,
    Set<String> genres,
    Set<String> instruments,
    Set<String> locations,
    int? minFollowers,
    int? maxFollowers,
    bool? isOnline,
    bool? isVerified,
  ) {
    return results.where((musician) {
      // 장르 필터
      if (genres.isNotEmpty && !genres.contains(musician['genre'])) {
        return false;
      }
      
      // 악기 필터
      if (instruments.isNotEmpty && !instruments.contains(musician['instrument'])) {
        return false;
      }
      
      // 지역 필터
      if (locations.isNotEmpty && !locations.contains(musician['location'])) {
        return false;
      }
      
      // 팔로워 수 필터
      if (minFollowers != null && musician['followers'] < minFollowers) {
        return false;
      }
      if (maxFollowers != null && musician['followers'] > maxFollowers) {
        return false;
      }
      
      // 온라인 상태 필터
      if (isOnline != null && musician['isOnline'] != isOnline) {
        return false;
      }
      
      // 인증 상태 필터
      if (isVerified != null && musician['verified'] != isVerified) {
        return false;
      }
      
      return true;
    }).toList();
  }

  /// 검색 통계 생성
  static Map<String, dynamic> generateSearchStats(List<Map<String, dynamic>> results) {
    if (results.isEmpty) {
      return {
        'total': 0,
        'online': 0,
        'verified': 0,
        'genres': {},
        'instruments': {},
        'locations': {},
      };
    }
    
    Map<String, int> genres = {};
    Map<String, int> instruments = {};
    Map<String, int> locations = {};
    int online = 0;
    int verified = 0;
    
    for (var musician in results) {
      // 온라인/인증 카운트
      if (musician['isOnline']) online++;
      if (musician['verified']) verified++;
      
      // 장르/악기/지역 분포
      genres[musician['genre']] = (genres[musician['genre']] ?? 0) + 1;
      instruments[musician['instrument']] = (instruments[musician['instrument']] ?? 0) + 1;
      locations[musician['location']] = (locations[musician['location']] ?? 0) + 1;
    }
    
    return {
      'total': results.length,
      'online': online,
      'verified': verified,
      'genres': genres,
      'instruments': instruments,
      'locations': locations,
    };
  }
} 