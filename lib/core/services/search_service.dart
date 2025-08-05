import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/search_utils.dart';

/// 고급 검색 서비스 - 캐싱, 에러 처리, 성능 최적화
class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  // 캐시 관리
  final Map<String, Map<String, dynamic>> _searchCache = LinkedHashMap<String, Map<String, dynamic>>();
  final Map<String, DateTime> _cacheTimestamps = LinkedHashMap<String, DateTime>();
  static const Duration _cacheExpiration = Duration(minutes: 10);

  // 검색 히스토리 관리
  static const String _historyKey = 'search_history';
  static const String _favoritesKey = 'search_favorites';
  static const int _maxHistorySize = 50;

  // 에러 처리
  String? _lastError;
  bool _isNetworkError = false;

  /// 고급 검색 실행
  Future<List<Map<String, dynamic>>> performAdvancedSearch({
    required String query,
    required List<Map<String, dynamic>> musicians,
    Set<String> genres = const {},
    Set<String> instruments = const {},
    Set<String> locations = const {},
    String sortBy = 'relevance',
    String sortOrder = 'desc',
    int? minFollowers,
    int? maxFollowers,
    bool? isOnline,
    bool? isVerified,
    bool useCache = true,
  }) async {
    try {
      // 캐시 키 생성
      String cacheKey = SearchUtils.generateCacheKey(
        query, genres, instruments, locations, sortBy, sortOrder,
      );

      // 캐시 확인
      if (useCache && _isCacheValid(cacheKey)) {
        return _searchCache[cacheKey]!['results'];
      }

      // 검색 실행
      List<Map<String, dynamic>> results = await _executeSearch(
        query: query,
        musicians: musicians,
        genres: genres,
        instruments: instruments,
        locations: locations,
        sortBy: sortBy,
        sortOrder: sortOrder,
        minFollowers: minFollowers,
        maxFollowers: maxFollowers,
        isOnline: isOnline,
        isVerified: isVerified,
      );

      // 캐시 저장
      _saveToCache(cacheKey, results);

      // 검색 히스토리 저장
      if (query.isNotEmpty) {
        await _saveSearchHistory(query);
      }

      _clearError();
      return results;

    } catch (e) {
      _setError('검색 중 오류가 발생했습니다: $e');
      return [];
    }
  }

  /// 검색 실행 (핵심 로직)
  Future<List<Map<String, dynamic>>> _executeSearch({
    required String query,
    required List<Map<String, dynamic>> musicians,
    required Set<String> genres,
    required Set<String> instruments,
    required Set<String> locations,
    required String sortBy,
    required String sortOrder,
    int? minFollowers,
    int? maxFollowers,
    bool? isOnline,
    bool? isVerified,
  }) async {
    // 검색어 토큰화
    List<String> searchTerms = SearchUtils.tokenizeQuery(query);
    
    // 기본 필터링
    List<Map<String, dynamic>> filteredResults = musicians;

    // 고급 필터링 적용
    filteredResults = SearchUtils.filterSearchResults(
      filteredResults,
      genres,
      instruments,
      locations,
      minFollowers,
      maxFollowers,
      isOnline,
      isVerified,
    );

    // 검색어가 있는 경우 검색 실행
    if (query.isNotEmpty) {
      filteredResults = _applySearchQuery(filteredResults, query, searchTerms);
    }

    // 정렬 적용
    filteredResults = SearchUtils.sortSearchResults(
      filteredResults,
      sortBy,
      sortOrder,
      query,
    );

    return filteredResults;
  }

  /// 검색어 적용
  List<Map<String, dynamic>> _applySearchQuery(
    List<Map<String, dynamic>> musicians,
    String query,
    List<String> searchTerms,
  ) {
    List<Map<String, dynamic>> results = [];

    for (var musician in musicians) {
      double score = SearchUtils.calculateTagScore(musician, query, searchTerms);
      
      // 최소 점수 이상인 결과만 포함
      if (score > 0.1) {
        results.add({
          ...musician,
          'searchScore': score,
        });
      }
    }

    return results;
  }

  /// 검색 제안 생성
  Future<List<String>> getSearchSuggestions(
    String partialQuery,
    List<Map<String, dynamic>> musicians,
  ) async {
    try {
      if (partialQuery.isEmpty) return [];

      // 캐시된 제안 확인
      String cacheKey = 'suggestions_$partialQuery';
      if (_isCacheValid(cacheKey)) {
        return _searchCache[cacheKey]!['suggestions'];
      }

      // 제안 생성
      List<String> suggestions = SearchUtils.generateSearchSuggestions(
        partialQuery,
        musicians,
      );

      // 캐시 저장 (짧은 만료 시간)
      _saveToCache(cacheKey, {'suggestions': suggestions}, Duration(minutes: 2));

      return suggestions;

    } catch (e) {
      _setError('검색 제안 생성 중 오류가 발생했습니다: $e');
      return [];
    }
  }

  /// 검색 히스토리 관리
  Future<List<String>> getSearchHistory() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_historyKey) ?? [];
      return history;
    } catch (e) {
      _setError('검색 히스토리 로드 중 오류가 발생했습니다: $e');
      return [];
    }
  }

  Future<void> _saveSearchHistory(String query) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_historyKey) ?? [];
      
      // 중복 제거
      history.remove(query);
      history.insert(0, query);
      
      // 크기 제한
      if (history.length > _maxHistorySize) {
        history = history.take(_maxHistorySize).toList();
      }
      
      await prefs.setStringList(_historyKey, history);
    } catch (e) {
      _setError('검색 히스토리 저장 중 오류가 발생했습니다: $e');
    }
  }

  /// 즐겨찾기 검색 관리
  Future<Set<String>> getFavoriteSearches() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];
      return LinkedHashSet<String>.from(favorites);
    } catch (e) {
      _setError('즐겨찾기 로드 중 오류가 발생했습니다: $e');
      return LinkedHashSet<String>();
    }
  }

  Future<void> toggleFavoriteSearch(String query) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];
      
      if (favorites.contains(query)) {
        favorites.remove(query);
      } else {
        favorites.add(query);
      }
      
      await prefs.setStringList(_favoritesKey, favorites);
    } catch (e) {
      _setError('즐겨찾기 업데이트 중 오류가 발생했습니다: $e');
    }
  }

  /// 캐시 관리
  bool _isCacheValid(String key) {
    if (!_searchCache.containsKey(key)) return false;
    
    DateTime? timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheExpiration;
  }

  void _saveToCache(String key, dynamic data, [Duration? expiration]) {
    _searchCache[key] = {'results': data};
    _cacheTimestamps[key] = DateTime.now();
  }

  void clearCache() {
    _searchCache.clear();
    _cacheTimestamps.clear();
  }

  /// 에러 처리
  void _setError(String error) {
    _lastError = error;
    _isNetworkError = error.contains('네트워크') || error.contains('연결');
  }

  void _clearError() {
    _lastError = null;
    _isNetworkError = false;
  }

  String? get lastError => _lastError;
  bool get isNetworkError => _isNetworkError;
  bool get hasError => _lastError != null;

  /// 검색 통계 생성
  Map<String, dynamic> generateSearchStats(List<Map<String, dynamic>> results) {
    return SearchUtils.generateSearchStats(results);
  }

  /// 검색 결과 내보내기
  Future<String> exportSearchResults(List<Map<String, dynamic>> results) async {
    try {
      Map<String, dynamic> exportData = {
        'timestamp': DateTime.now().toIso8601String(),
        'totalResults': results.length,
        'results': results.map((result) => {
          'name': result['name'],
          'genre': result['genre'],
          'instrument': result['instrument'],
          'location': result['location'],
          'followers': result['followers'],
          'bio': result['bio'],
        }).toList(),
      };

      return jsonEncode(exportData);
    } catch (e) {
      _setError('검색 결과 내보내기 중 오류가 발생했습니다: $e');
      return '';
    }
  }

  /// 검색 성능 최적화
  Future<void> preloadSearchData(List<Map<String, dynamic>> musicians) async {
    try {
      // 인덱스 생성
      await _buildSearchIndex(musicians);
      
      // 자주 사용되는 검색어 미리 계산
      await _precomputeCommonSearches(musicians);
      
    } catch (e) {
      _setError('검색 데이터 사전 로드 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _buildSearchIndex(List<Map<String, dynamic>> musicians) async {
    // 검색 인덱스 구축 (향후 확장용)
    // 현재는 기본 구현
  }

  Future<void> _precomputeCommonSearches(List<Map<String, dynamic>> musicians) async {
    // 자주 사용되는 검색어 미리 계산
    List<String> commonTerms = ['재즈', '팝', '락', '기타', '피아노', '서울'];
    
    for (String term in commonTerms) {
      String cacheKey = 'common_$term';
      if (!_isCacheValid(cacheKey)) {
        List<Map<String, dynamic>> results = await _executeSearch(
          query: term,
          musicians: musicians,
          genres: {},
          instruments: {},
          locations: {},
          sortBy: 'relevance',
          sortOrder: 'desc',
        );
        _saveToCache(cacheKey, results, Duration(minutes: 30));
      }
    }
  }
} 