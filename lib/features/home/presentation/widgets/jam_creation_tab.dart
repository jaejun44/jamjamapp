import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/auth_state_manager.dart';
import 'package:jamjamapp/core/services/profile_image_manager.dart';
import 'package:jamjamapp/core/services/app_state_manager.dart';
import 'package:jamjamapp/features/home/presentation/widgets/user_profile_screen.dart';
import 'dart:async';
import 'dart:io';

class JamCreationTab extends StatefulWidget {
  const JamCreationTab({super.key});

  @override
  State<JamCreationTab> createState() => _JamCreationTabState();
}

class _JamCreationTabState extends State<JamCreationTab> with AutomaticKeepAliveClientMixin {
  final AppStateManager _appStateManager = AppStateManager.instance;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _genreController = TextEditingController();
  final _instrumentsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  
  bool _isCreating = false;
  bool _isUploading = false;
  
  // 참여인원 수 설정
  int _maxParticipants = 5;
  
  // 실시간 업데이트 상태
  Timer? _realtimeUpdateTimer;
  bool _isRealtimeUpdateEnabled = true;
  
  // 검색 및 필터 상태
  String _searchQuery = '';
  String _selectedFilter = '전체';
  final List<String> _filterOptions = ['전체', '모집 중', '진행 중', '완료'];
  
  // 업로드된 파일들
  List<Map<String, dynamic>> _uploadedFiles = [];
  Uint8List? _uploadedMediaData;
  String? _uploadedMediaType;

  // 이미지 피커
  final ImagePicker _picker = ImagePicker();

  // 🔄 잼 세션 데이터 안전한 관리 (ListView 호환)
  List<Map<String, dynamic>> _recentJamSessions = [];

  // 기본 더미 데이터 (최초 실행 시에만 사용)
  final List<Map<String, dynamic>> _defaultJamSessions = [
    {
      'id': 1,
      'title': '재즈 팝 퓨전 세션',
      'genre': '재즈, 팝',
      'instruments': '기타, 피아노, 드럼',
      'participants': 3, // participantsList.length와 동기화됨
      'maxParticipants': 5,
      'status': '모집 중',
      'createdBy': 'JamMaster1',
      'createdAt': '2시간 전',
      'description': '재즈와 팝을 결합한 새로운 퓨전 음악을 만들어봐요!',
      'tags': ['재즈', '팝', '퓨전'],
      'isLive': false,
      'recordingUrl': null,
      'files': [],
      'chat': [],
      'participantsList': [
        {
          'id': 1,
          'name': 'JamMaster1',
          'avatar': '🎷',
          'role': '방장',
          'instruments': ['색소폰', '피아노'],
          'isOnline': true,
          'joinTime': '2시간 전',
        },
        {
          'id': 2,
          'name': 'GuitarHero3',
          'avatar': '🎸',
          'role': '참여자',
          'instruments': ['기타'],
          'isOnline': true,
          'joinTime': '1시간 전',
        },
        {
          'id': 3,
          'name': 'PianoLover',
          'avatar': '🎹',
          'role': '참여자',
          'instruments': ['피아노'],
          'isOnline': false,
          'joinTime': '30분 전',
        },
      ],
    },
    {
      'id': 2,
      'title': '락 밴드 오디션',
      'genre': '락',
      'instruments': '기타, 베이스, 드럼, 보컬',
      'participants': 5, // participantsList.length와 동기화됨 
      'maxParticipants': 6,
      'status': '진행 중',
      'createdBy': 'GuitarHero3',
      'createdAt': '1일 전',
      'description': '락 밴드 멤버를 찾고 있습니다. 열정적인 뮤지션 환영!',
      'tags': ['락', '밴드', '오디션'],
      'isLive': true,
      'recordingUrl': 'https://example.com/recording1',
      'files': [
        {'name': '기타_리프.mp3', 'type': 'audio', 'size': '2.3MB'},
        {'name': '드럼_패턴.mp3', 'type': 'audio', 'size': '1.8MB'},
      ],
      'chat': [
        {'user': 'GuitarHero3', 'message': '기타 리프 업로드했어요!', 'time': '5분 전'},
        {'user': 'Drummer5', 'message': '드럼 패턴도 올렸습니다', 'time': '3분 전'},
      ],
      'participantsList': [
        {
          'id': 1,
          'name': 'GuitarHero3',
          'avatar': '🎸',
          'role': '방장',
          'instruments': ['기타', '베이스'],
          'isOnline': true,
          'joinTime': '1일 전',
        },
        {
          'id': 2,
          'name': 'Drummer5',
          'avatar': '🥁',
          'role': '참여자',
          'instruments': ['드럼'],
          'isOnline': true,
          'joinTime': '20시간 전',
        },
        {
          'id': 3,
          'name': 'BassPlayer1',
          'avatar': '🎵',
          'role': '참여자',
          'instruments': ['베이스'],
          'isOnline': false,
          'joinTime': '18시간 전',
        },
        {
          'id': 4,
          'name': 'VocalStar',
          'avatar': '🎤',
          'role': '참여자',
          'instruments': ['보컬'],
          'isOnline': true,
          'joinTime': '12시간 전',
        },
        {
          'id': 5,
          'name': 'RockFan99',
          'avatar': '🤘',
          'role': '참여자',
          'instruments': ['기타'],
          'isOnline': false,
          'joinTime': '10시간 전',
        },
      ],
    },
    {
      'id': 3,
      'title': '클래식 듀오',
      'genre': '클래식',
      'instruments': '피아노, 바이올린',
      'participants': 2, // participantsList.length와 동기화됨
      'maxParticipants': 2,
      'status': '완료',
      'createdBy': 'Pianist4',
      'createdAt': '3일 전',
      'description': '베토벤 소나타를 함께 연주해봐요.',
      'tags': ['클래식', '피아노', '바이올린'],
      'isLive': false,
      'recordingUrl': 'https://example.com/recording2',
      'files': [
        {'name': '베토벤_소나타.pdf', 'type': 'sheet', 'size': '1.2MB'},
        {'name': '연주_영상.mp4', 'type': 'video', 'size': '15.7MB'},
      ],
      'chat': [
        {'user': 'Pianist4', 'message': '연주 영상 업로드 완료!', 'time': '1일 전'},
        {'user': 'Violinist6', 'message': '정말 아름다운 연주였어요', 'time': '1일 전'},
      ],
      'participantsList': [
        {
          'id': 1,
          'name': 'Pianist4',
          'avatar': '🎹',
          'role': '방장',
          'instruments': ['피아노'],
          'isOnline': false,
          'joinTime': '3일 전',
        },
        {
          'id': 2,
          'name': 'Violinist6',
          'avatar': '🎻',
          'role': '참여자',
          'instruments': ['바이올린'],
          'isOnline': false,
          'joinTime': '3일 전',
        },
      ],
    },
  ];

  // 참여 신청 대기 목록
  final List<Map<String, dynamic>> _pendingJoinRequests = [];

  @override
  void initState() {
    super.initState();
    _initializeJamData();
    _startRealtimeUpdates();
  }

  /// 잼 데이터 초기화 (ListView 안전성 보장)
  void _initializeJamData() {
    try {
      final currentJamSessions = _appStateManager.jamState['jamSessions'] as List<Map<String, dynamic>>?;
      if (currentJamSessions == null || currentJamSessions.isEmpty) {
        // 최초 실행 시 기본 더미 데이터 사용
        _recentJamSessions = List<Map<String, dynamic>>.from(_defaultJamSessions);
        _appStateManager.updateValue('jam', 'jamSessions', _recentJamSessions);
        print('🎵 잼 탭: 기본 데이터 초기화 완료 (${_recentJamSessions.length}개 세션)');
      } else {
        // 기존 데이터 로드
        _recentJamSessions = List<Map<String, dynamic>>.from(currentJamSessions);
        print('🎵 잼 탭: 기존 데이터 로드 완료 (${_recentJamSessions.length}개 세션)');
      }
    } catch (e) {
      print('❌ 잼 데이터 초기화 실패: $e');
      // 안전한 폴백: 기본 데이터 사용
      _recentJamSessions = List<Map<String, dynamic>>.from(_defaultJamSessions);
    }
  }

  /// 잼 세션 데이터 저장
  void _saveJamSessions() {
    _appStateManager.updateValue('jam', 'jamSessions', _recentJamSessions);
    print('💾 잼 세션 데이터 저장 완료: ${_recentJamSessions.length}개');
  }

  /// AppStateManager에서 데이터 동기화 (탭 재진입 시)
  void _syncDataFromAppStateManager() {
    try {
      final currentJamSessions = _appStateManager.jamState['jamSessions'] as List<Map<String, dynamic>>?;
      if (currentJamSessions != null && currentJamSessions.isNotEmpty) {
        // 현재 데이터와 다르면 동기화
        if (_recentJamSessions.length != currentJamSessions.length) {
          _recentJamSessions = List<Map<String, dynamic>>.from(currentJamSessions);
          print('🔄 잼 탭: AppStateManager와 데이터 동기화 완료 (${_recentJamSessions.length}개 세션)');
        }
      }
    } catch (e) {
      print('⚠️ 데이터 동기화 실패: $e');
    }
  }

  @override
  void dispose() {
    _realtimeUpdateTimer?.cancel();
    _titleController.dispose();
    _genreController.dispose();
    _instrumentsController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    // 종료 시 최종 저장
    _saveJamSessions();
    super.dispose();
  }

  @override
  void deactivate() {
    // 탭 전환 시에도 저장
    _saveJamSessions();
    super.deactivate();
  }

  /// 실시간 업데이트 시작
  void _startRealtimeUpdates() {
    _realtimeUpdateTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_isRealtimeUpdateEnabled && mounted) {
        _simulateJamUpdates();
      }
    });
  }

  /// Jam 업데이트 시뮬레이션 (participantsList 동기화)
  void _simulateJamUpdates() {
    final random = DateTime.now().millisecondsSinceEpoch % _recentJamSessions.length;
    if (random < _recentJamSessions.length) {
      setState(() {
        final jam = _recentJamSessions[random];
        final participantsList = List<Map<String, dynamic>>.from(jam['participantsList'] ?? []);
        
        if (jam['status'] == '모집 중' && participantsList.length < jam['maxParticipants']) {
          // 🔄 동적 참여자 추가 (시뮬레이션)
          final dummyNames = ['MusicLover', 'JamFan', 'Guitarist99', 'Drummer2', 'Singer5'];
          final dummyAvatars = ['🎵', '🎶', '🎸', '🥁', '🎤'];
          final dummyInstruments = [
            ['기타'], ['피아노'], ['드럼'], ['베이스'], ['보컬']
          ];
          
          final newIndex = participantsList.length % dummyNames.length;
          
          participantsList.add({
            'id': participantsList.length + 1,
            'name': '${dummyNames[newIndex]}${DateTime.now().millisecond}',
            'avatar': dummyAvatars[newIndex],
            'role': '참여자',
            'instruments': dummyInstruments[newIndex],
            'isOnline': true,
            'joinTime': '방금 전',
          });
          
          // 잼 세션 업데이트
          jam['participantsList'] = participantsList;
          jam['participants'] = participantsList.length;
          
          if (participantsList.length >= jam['maxParticipants']) {
            jam['status'] = '진행 중';
          }
          
          print('🔄 시뮬레이션: ${jam['title']} 참여자 ${participantsList.length}명');
        }
      });
    }
  }

  /// Jam 세션 필터링
  List<Map<String, dynamic>> _filterJamSessions() {
    List<Map<String, dynamic>> filtered = _recentJamSessions;

    // 검색 필터
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((jam) {
        final query = _searchQuery.toLowerCase();
        return jam['title'].toLowerCase().contains(query) ||
               jam['genre'].toLowerCase().contains(query) ||
               jam['instruments'].toLowerCase().contains(query) ||
               jam['description'].toLowerCase().contains(query);
      }).toList();
    }

    // 상태 필터
    if (_selectedFilter != '전체') {
      filtered = filtered.where((jam) => jam['status'] == _selectedFilter).toList();
    }

    return filtered;
  }

  /// 파일 업로드 (실제 파일 선택)
  Future<void> _uploadFile() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // 파일 타입 선택 다이얼로그
      final String? fileType = await _showFileTypeDialog();
      if (fileType == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      XFile? pickedFile;
      
      switch (fileType) {
        case 'image':
          pickedFile = await _picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 85,
          );
          break;
        case 'video':
          pickedFile = await _picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 10),
          );
          break;
        case 'audio':
          // 웹에서는 파일 선택 다이얼로그 사용
          pickedFile = await _picker.pickMedia();
          break;
        case 'document':
          // 웹에서는 파일 선택 다이얼로그 사용
          pickedFile = await _picker.pickMedia();
          break;
      }

      if (pickedFile != null) {
        // 파일 정보 가져오기
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        final fileName = pickedFile.name;
        final fileExtension = fileName.split('.').last.toLowerCase();

        // 파일 타입 결정
        String fileType = 'document';
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension)) {
          fileType = 'image';
        } else if (['mp4', 'avi', 'mov', 'wmv'].contains(fileExtension)) {
          fileType = 'video';
        } else if (['mp3', 'wav', 'aac', 'flac'].contains(fileExtension)) {
          fileType = 'audio';
        }

        setState(() {
          _uploadedFiles.add({
            'name': fileName,
            'type': fileType,
            'size': _formatFileSize(fileSize),
            'path': pickedFile?.path ?? 'unknown_path',
            'uploadTime': DateTime.now(),
          });
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fileName 업로드 완료!'),
            backgroundColor: AppTheme.accentPink,
          ),
        );
      } else {
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('파일 업로드 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 파일 타입 선택 다이얼로그
  Future<String?> _showFileTypeDialog() {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text(
          '파일 타입 선택',
          style: TextStyle(color: AppTheme.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFileTypeOption('image', '이미지', Icons.image),
            _buildFileTypeOption('video', '영상', Icons.videocam),
            _buildFileTypeOption('audio', '음악', Icons.music_note),
            _buildFileTypeOption('document', '문서', Icons.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소', style: TextStyle(color: AppTheme.grey)),
          ),
        ],
      ),
    );
  }

  /// 파일 타입 옵션 위젯
  Widget _buildFileTypeOption(String type, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accentPink),
      title: Text(title, style: const TextStyle(color: AppTheme.white)),
      onTap: () => Navigator.of(context).pop(type),
    );
  }

  /// 파일 크기 포맷팅
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Jam 세션 참여
  void _joinJamSession(Map<String, dynamic> jamSession) {
    // 로그인 상태 확인
    if (AuthStateManager.instance.requiresLogin) {
      AuthStateManager.instance.showLoginRequiredMessage(context);
      return;
    }

    // 방장인지 확인
    final isHost = jamSession['createdBy'] == AuthStateManager.instance.userName;
    
    if (isHost) {
      // 방장인 경우 바로 참여
      _showSuccessDialog('Jam 세션에 참여했습니다! 🎵');
    } else {
      // 일반 사용자인 경우 참여 신청
      _showJoinRequestDialog(jamSession);
    }
  }

  /// 참여 신청 다이얼로그
  void _showJoinRequestDialog(Map<String, dynamic> jamSession) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text(
          '참여 신청',
          style: TextStyle(color: AppTheme.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${jamSession['title']}',
              style: const TextStyle(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '방장 ${jamSession['createdBy']}님의 승인을 기다리는 중입니다.',
              style: const TextStyle(color: AppTheme.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlack,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '참여 정보',
                    style: TextStyle(
                      color: AppTheme.accentPink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '악기: 피아노, 기타',
                    style: const TextStyle(color: AppTheme.white),
                  ),
                  Text(
                    '참여 목적: 음악 협업 및 연주',
                    style: const TextStyle(color: AppTheme.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소', style: TextStyle(color: AppTheme.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _submitJoinRequest(jamSession);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink),
            child: const Text('신청하기'),
          ),
        ],
      ),
    );
  }

  /// 참여 신청 제출 (시뮬레이션: 즉시 승인)
  void _submitJoinRequest(Map<String, dynamic> jamSession) {
    // 🔄 실제 participantsList 업데이트
    final participantsList = List<Map<String, dynamic>>.from(jamSession['participantsList'] ?? []);
    final currentUser = AuthStateManager.instance.userName;
    
    // 이미 참여한 사용자인지 확인
    final isAlreadyJoined = participantsList.any((p) => p['name'] == currentUser);
    
    if (isAlreadyJoined) {
      _showSuccessDialog('이미 참여한 세션입니다! 🎵');
      return;
    }
    
    // 최대 참여자 수 확인
    if (participantsList.length >= jamSession['maxParticipants']) {
      _showSuccessDialog('참여자가 가득 찼습니다. 😔');
      return;
    }
    
    setState(() {
      // 1. participantsList에 새 참여자 추가
      participantsList.add({
        'id': participantsList.length + 1,
        'name': currentUser,
        'avatar': '👤',
        'role': '참여자',
        'instruments': ['기타'], // 기본값
        'isOnline': true,
        'joinTime': '방금 전',
      });
      
      // 2. jamSession 업데이트
      jamSession['participantsList'] = participantsList;
      jamSession['participants'] = participantsList.length;
      
      // 3. 최대 인원 도달 시 상태 변경
      if (participantsList.length >= jamSession['maxParticipants']) {
        jamSession['status'] = '진행 중';
      }
      
      print('✅ 잼 참여 완료: ${jamSession['title']}');
      print('✅ 새로운 참여자 수: ${participantsList.length}/${jamSession['maxParticipants']}');
    });
    _saveJamSessions();
    
    // 전체 잼 세션 목록 다시 로드하여 UI 즉시 업데이트
    _loadJamSessionsFromAppState();

    _showSuccessDialog('잼 세션에 참여했습니다! 🎵');
  }

  /// 성공 다이얼로그
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text(
          '성공!',
          style: TextStyle(color: AppTheme.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.white),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 방장 승인 관리 다이얼로그
  void _showHostApprovalDialog(Map<String, dynamic> jamSession) {
    // 시뮬레이션된 참여 신청 목록
    final List<Map<String, dynamic>> joinRequests = [
      {
        'id': 1,
        'userName': 'GuitarHero3',
        'userAvatar': '🎸',
        'instruments': ['기타'],
        'requestTime': '2분 전',
        'message': '기타 연주하고 싶습니다!',
        'status': 'pending',
      },
      {
        'id': 2,
        'userName': 'Drummer5',
        'userAvatar': '🥁',
        'instruments': ['드럼'],
        'requestTime': '5분 전',
        'message': '드럼 세팅 완료했습니다!',
        'status': 'pending',
      },
      {
        'id': 3,
        'userName': 'BassPlayer',
        'userAvatar': '🎸',
        'instruments': ['베이스'],
        'requestTime': '10분 전',
        'message': '베이스 라인 추가하겠습니다!',
        'status': 'approved',
      },
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.secondaryBlack,
            title: Row(
              children: [
                const Text(
                  '참여 신청 관리',
                  style: TextStyle(color: AppTheme.white),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppTheme.white),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  Text(
                    '${jamSession['title']}',
                    style: const TextStyle(
                      color: AppTheme.accentPink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: joinRequests.length,
                      itemBuilder: (context, index) {
                        final request = joinRequests[index];
                        return _buildJoinRequestCard(request, setState);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 참여 신청 카드
  Widget _buildJoinRequestCard(Map<String, dynamic> request, StateSetter setState) {
    final status = request['status'];
    final isPending = status == 'pending';
    
    return Card(
      color: AppTheme.primaryBlack,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.accentPink,
                  child: Text(
                    request['userAvatar'],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['userName'],
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '악기: ${request['instruments'].join(', ')}',
                        style: const TextStyle(color: AppTheme.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request['message'],
              style: const TextStyle(color: AppTheme.white),
            ),
            const SizedBox(height: 8),
            Text(
              '신청 시간: ${request['requestTime']}',
              style: const TextStyle(color: AppTheme.grey, fontSize: 10),
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          request['status'] = 'approved';
                        });
                        _showSuccessDialog('${request['userName']}님의 참여 신청을 수락했습니다!');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        '수락',
                        style: TextStyle(color: AppTheme.white, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          request['status'] = 'rejected';
                        });
                        _showSuccessDialog('${request['userName']}님의 참여 신청을 거부했습니다.');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        '거부',
                        style: TextStyle(color: AppTheme.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 승인/거절 결과 표시
  void _showApprovalResult(String action, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: Text(
          '$action 완료',
          style: const TextStyle(color: AppTheme.white),
        ),
        content: Text(
          '$userName님의 참여 신청을 $action했습니다.',
          style: const TextStyle(color: AppTheme.white),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 상태별 색상 반환
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case '모집중':
        return Colors.blue;
      case '진행 중':
        return Colors.green;
      case '완료':
        return Colors.grey;
      default:
        return AppTheme.grey;
    }
  }

  /// 상태별 텍스트 반환
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '대기중';
      case 'approved':
        return '승인됨';
      case 'rejected':
        return '거절됨';
      default:
        return '알 수 없음';
    }
  }

  /// Jam 생성 모달 표시
  void _showJamCreationModal() {
    // 로그인 상태 확인
    if (AuthStateManager.instance.requiresLogin) {
      AuthStateManager.instance.showLoginRequiredMessage(context);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildJamCreationModal(),
    );
  }

  /// Jam 생성 모달
  Widget _buildJamCreationModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Text(
                '새 Jam 세션 생성',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppTheme.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 폼
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Jam 제목',
                        labelStyle: TextStyle(color: AppTheme.grey),
                        hintText: '예: 재즈 팝 퓨전 세션',
                        hintStyle: TextStyle(color: AppTheme.grey),
                      ),
                      style: const TextStyle(color: AppTheme.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jam 제목을 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 장르
                    TextFormField(
                      controller: _genreController,
                      decoration: const InputDecoration(
                        labelText: '장르',
                        labelStyle: TextStyle(color: AppTheme.grey),
                        hintText: '예: 재즈, 팝, 락',
                        hintStyle: TextStyle(color: AppTheme.grey),
                      ),
                      style: const TextStyle(color: AppTheme.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '장르를 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 필요한 악기
                    TextFormField(
                      controller: _instrumentsController,
                      decoration: const InputDecoration(
                        labelText: '필요한 악기',
                        labelStyle: TextStyle(color: AppTheme.grey),
                        hintText: '예: 기타, 베이스, 드럼',
                        hintStyle: TextStyle(color: AppTheme.grey),
                      ),
                      style: const TextStyle(color: AppTheme.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '필요한 악기를 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 최대 참여자 수
                    TextFormField(
                      controller: _maxParticipantsController,
                      decoration: const InputDecoration(
                        labelText: '최대 참여자 수',
                        labelStyle: TextStyle(color: AppTheme.grey),
                        hintText: '예: 5',
                        hintStyle: TextStyle(color: AppTheme.grey),
                      ),
                      style: const TextStyle(color: AppTheme.white),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '최대 참여자 수를 입력해주세요.';
                        }
                        final number = int.tryParse(value);
                        if (number == null || number < 1) {
                          return '유효한 숫자를 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 미디어 업로드 섹션
                    const Text(
                      '미디어 업로드 (선택사항)',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showFileUploadModal('image'),
                            icon: const Icon(Icons.photo, color: AppTheme.white),
                            label: const Text('이미지', style: TextStyle(color: AppTheme.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentPink,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showFileUploadModal('video'),
                            icon: const Icon(Icons.videocam, color: AppTheme.white),
                            label: const Text('비디오', style: TextStyle(color: AppTheme.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentPink,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showFileUploadModal('audio'),
                            icon: const Icon(Icons.music_note, color: AppTheme.white),
                            label: const Text('오디오', style: TextStyle(color: AppTheme.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentPink,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // 업로드된 미디어 표시
                    if (_uploadedMediaData != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlack,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getMediaIcon(_uploadedMediaType ?? ''),
                                  color: AppTheme.accentPink,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '업로드된 미디어',
                                  style: const TextStyle(
                                    color: AppTheme.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _uploadedMediaData = null;
                                      _uploadedMediaType = null;
                                    });
                                  },
                                  icon: const Icon(Icons.close, color: AppTheme.grey, size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_uploadedMediaType == 'image')
                              Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: MemoryImage(_uploadedMediaData!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 80,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryBlack,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _getMediaIcon(_uploadedMediaType ?? ''),
                                        color: AppTheme.accentPink,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getMediaTypeText(_uploadedMediaType ?? ''),
                                        style: const TextStyle(color: AppTheme.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // 설명
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '설명',
                        labelStyle: TextStyle(color: AppTheme.grey),
                        hintText: 'Jam 세션에 대한 설명을 작성해주세요...',
                        hintStyle: TextStyle(color: AppTheme.grey),
                      ),
                      style: const TextStyle(color: AppTheme.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 생성 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCreating ? null : _createJamSession,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink),
              child: _isCreating 
                  ? const SizedBox(
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                      ),
                    )
                  : const Text('Jam 생성하기'),
            ),
          ),
        ],
      ),
    );
  }

  /// 파일 아이콘 가져오기
  IconData _getFileIcon(String type) {
    switch (type) {
      case 'audio':
        return Icons.audiotrack;
      case 'video':
        return Icons.videocam;
      case 'image':
        return Icons.image;
      case 'sheet':
        return Icons.music_note;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _createJamSession() async {
    // 로그인 상태 확인
    if (AuthStateManager.instance.requiresLogin) {
      AuthStateManager.instance.showLoginRequiredMessage(context);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      // Jam 세션 생성 시뮬레이션
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // 새 Jam 세션 추가
        final newJamSession = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'title': _titleController.text,
          'genre': _genreController.text,
          'instruments': _instrumentsController.text,
          'participants': 1,
          'maxParticipants': int.tryParse(_maxParticipantsController.text) ?? 5,
          'status': '모집 중',
          'createdBy': AuthStateManager.instance.userName,
          'createdAt': '방금 전',
          'description': _descriptionController.text,
          'tags': _genreController.text.split(',').map((e) => e.trim()).toList(),
          'isLive': false,
          'recordingUrl': null,
          'files': _uploadedFiles,
          'mediaData': _uploadedMediaData,
          'mediaType': _uploadedMediaType,
          'chat': [],
          // 🔄 동적 participants 리스트 추가
          'participantsList': [
            {
              'id': 1,
              'name': AuthStateManager.instance.userName,
              'avatar': '👤',
              'role': '방장',
              'instruments': ['기타', '피아노'],
              'isOnline': true,
              'joinTime': '방금 전',
            }
          ],
        };

        setState(() {
          _recentJamSessions.insert(0, newJamSession);
        });
        _saveJamSessions();

        // 폼 초기화
        _titleController.clear();
        _genreController.clear();
        _instrumentsController.clear();
        _descriptionController.clear();
        _maxParticipantsController.clear();
        _uploadedFiles.clear();
        _uploadedMediaData = null;
        _uploadedMediaType = null;

        Navigator.of(context).pop(); // 모달 닫기

        print('✅ 잼 세션 생성 완료 - UI 업데이트 중...');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jam 세션이 생성되었습니다!'),
            backgroundColor: AppTheme.accentPink,
          ),
        );
        
        print('✅ 잼 세션 생성 완료 - 모든 UI 업데이트 완료');
      }
    } catch (e) {
      print('❌ 잼 세션 생성 중 오류: $e');
      print('❌ 스택 트레이스: ${StackTrace.current}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jam 세션 생성 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  /// 사용자 프로필 보기
  void _showUserProfile(String username) {
    try {
      // 로그인 상태 확인
      if (AuthStateManager.instance.requiresLogin) {
        AuthStateManager.instance.showLoginRequiredMessage(context);
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(
            username: username,
            userAvatar: username == AuthStateManager.instance.userName ? '나' : '👤',
          ),
        ),
      );
    } catch (e) {
      print('❌ 사용자 프로필 화면 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('프로필 화면을 불러올 수 없습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Jam 세션 상세 보기
  void _showJamDetails(Map<String, dynamic> jamSession) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildJamDetailsModal(jamSession),
    );
  }

  /// Jam 세션 상세 모달
  Widget _buildJamDetailsModal(Map<String, dynamic> jamSession) {
    // 🔄 동적 참여자 데이터 사용
    final List<Map<String, dynamic>> participants = 
        List<Map<String, dynamic>>.from(jamSession['participantsList'] ?? []);
    
    print('✅ 잼 세션 ${jamSession['title']} 참여자 수: ${participants.length}');
    print('✅ 잼 세션 participants 숫자: ${jamSession['participants']}');

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Text(
                jamSession['title'],
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppTheme.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 상태 및 참여자 정보
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(jamSession['status']),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  jamSession['status'],
                  style: const TextStyle(color: AppTheme.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${participants.length}/${jamSession['maxParticipants']} 참여',
                style: const TextStyle(color: AppTheme.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 설명
          Text(
            '설명',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            jamSession['description'],
            style: const TextStyle(color: AppTheme.white),
          ),
          const SizedBox(height: 20),
          
          // 미디어 표시 (있는 경우)
          if (jamSession['mediaData'] != null) ...[
            Text(
              '미디어',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getMediaIcon(jamSession['mediaType']),
                        color: AppTheme.accentPink,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getMediaTypeText(jamSession['mediaType']),
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (jamSession['mediaType'] == 'image')
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: MemoryImage(jamSession['mediaData']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryBlack,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getMediaIcon(jamSession['mediaType']),
                              color: AppTheme.accentPink,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _getMediaTypeText(jamSession['mediaType']),
                              style: const TextStyle(
                                color: AppTheme.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // 태그
          Text(
            '태그',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: jamSession['tags'].map<Widget>((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: AppTheme.accentPink.withValues(alpha: 0.2),
                labelStyle: const TextStyle(color: AppTheme.accentPink),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          
          // 참여자 목록
          Text(
            '참여자 (${participants.length}명)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // 참여자 리스트
          Expanded(
            child: ListView.builder(
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final participant = participants[index];
                return _buildParticipantCard(participant, jamSession: jamSession);
              },
            ),
          ),
          
          // 파일 목록 (있는 경우)
          if (jamSession['files'] != null && jamSession['files'].isNotEmpty) ...[
            Text(
              '공유된 파일',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: jamSession['files'].length,
                itemBuilder: (context, index) {
                  final file = jamSession['files'][index];
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlack,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getFileIcon(file['type']),
                          color: AppTheme.accentPink,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          file['name'],
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 10,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          file['size'],
                          style: const TextStyle(
                            color: AppTheme.grey,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // 액션 버튼들
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _joinJamSession(jamSession);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink),
                  child: const Text('참여 신청'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showJamDetails(jamSession),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink),
                  child: const Text('상세 보기'),
                ),
              ),
            ],
          ),
          
          // 방장인 경우 참여 신청 관리 버튼 추가
          if (jamSession['createdBy'] == '락스타') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showHostApprovalDialog(jamSession);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.people, color: AppTheme.white),
                label: const Text(
                  '참여 신청 관리',
                  style: TextStyle(color: AppTheme.white),
                ),
              ),
            ),
          ],

          // 🚪 참여자 나가기/내보내기 버튼들
          const SizedBox(height: 16),
          _buildParticipantActionButtons(jamSession),
        ],
      ),
    );
  }

  /// 참여자 카드 위젯 (길게 누르기로 내보내기 지원)
  Widget _buildParticipantCard(Map<String, dynamic> participant, {Map<String, dynamic>? jamSession}) {
    final currentUser = AuthStateManager.instance.userName;
    final isCurrentUser = participant['name'] == currentUser;
    final isHost = participant['role'] == '방장';
    final canKick = jamSession != null && 
                   !isCurrentUser && 
                   !isHost && 
                   jamSession['participantsList'].any((p) => p['name'] == currentUser && p['role'] == '방장');
    
    return Card(
      color: AppTheme.primaryBlack,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onLongPress: canKick ? () => _kickParticipant(jamSession!, participant) : null,
        child: ListTile(
          leading: Stack(
          children: [
            // ProfileImageManager를 사용한 프로필 이미지 표시
            participant['name'] == AuthStateManager.instance.userName
                ? ProfileImageManager.instance.buildProfileImage(
                    radius: 20,
                    placeholder: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.accentPink,
                      child: Text(
                        participant['avatar'],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                : CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.accentPink,
                    child: Text(
                      participant['avatar'],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
            if (participant['isOnline'])
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryBlack, width: 2),
                  ),
                ),
              ),
          ],
        ),
          title: Row(
          children: [
            Text(
              participant['name'],
              style: const TextStyle(color: AppTheme.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: participant['role'] == '방장' 
                    ? AppTheme.accentPink 
                    : AppTheme.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                participant['role'],
                style: TextStyle(
                  color: participant['role'] == '방장' 
                      ? AppTheme.white 
                      : AppTheme.grey,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
          subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '악기: ${participant['instruments'].join(', ')}',
              style: const TextStyle(color: AppTheme.grey),
            ),
            Text(
              '참여: ${participant['joinTime']}',
              style: const TextStyle(color: AppTheme.grey, fontSize: 10),
            ),
          ],
        ),
          trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 내보내기 가능한 참여자 표시
            if (canKick)
              const Icon(
                Icons.touch_app,
                color: AppTheme.grey,
                size: 16,
              ),
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showUserProfile(participant['name']);
              },
              icon: const Icon(Icons.person, color: AppTheme.accentPink),
            ),
          ],
        ),
        ),
      ),
    );
  }

  /// Jam 채팅 보기
  void _showJamChat(Map<String, dynamic> jamSession) {
    // 시뮬레이션된 채팅 메시지 데이터
    List<Map<String, dynamic>> chatMessages = [
      {
        'id': 1,
        'user': 'JamMaster',
        'message': '안녕하세요! Jam 세션에 오신 것을 환영합니다! 🎵',
        'time': '14:30',
        'isMe': false,
      },
      {
        'id': 2,
        'user': 'GuitarHero3',
        'message': '안녕하세요! 기타 연주 준비되었습니다 🎸',
        'time': '14:31',
        'isMe': false,
      },
      {
        'id': 3,
        'user': 'Drummer5',
        'message': '드럼 세팅 완료! 🥁',
        'time': '14:32',
        'isMe': false,
      },
      {
        'id': 4,
        'user': '락스타',
        'message': '저도 참여할게요! 피아노 연주하겠습니다 🎹',
        'time': '14:33',
        'isMe': true,
      },
    ];

    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.secondaryBlack,
            title: Row(
              children: [
                Text(
                  '${jamSession['title']} 채팅',
                  style: const TextStyle(color: AppTheme.white),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppTheme.white),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // 채팅 메시지 영역
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlack,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        reverse: true,
                        itemCount: chatMessages.length,
                        itemBuilder: (context, index) {
                          final message = chatMessages[chatMessages.length - 1 - index];
                          return _buildChatMessage(message);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 메시지 입력 영역
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: const InputDecoration(
                            hintText: '메시지를 입력하세요...',
                            hintStyle: TextStyle(color: AppTheme.grey),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: const TextStyle(color: AppTheme.white),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              _sendChatMessage(value, chatMessages, setState, messageController);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          if (messageController.text.trim().isNotEmpty) {
                            _sendChatMessage(messageController.text, chatMessages, setState, messageController);
                          }
                        },
                        icon: const Icon(Icons.send, color: AppTheme.accentPink),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 채팅 메시지 위젯
  Widget _buildChatMessage(Map<String, dynamic> message) {
    final isMe = message['isMe'] ?? false;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            // ProfileImageManager를 사용한 프로필 이미지 표시
            message['user'] == AuthStateManager.instance.userName
                ? ProfileImageManager.instance.buildProfileImage(
                    radius: 16,
                    placeholder: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.accentPink,
                      child: Text(
                        message['user'][0],
                        style: const TextStyle(color: AppTheme.white, fontSize: 12),
                      ),
                    ),
                  )
                : CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.accentPink,
                    child: Text(
                      message['user'][0],
                      style: const TextStyle(color: AppTheme.white, fontSize: 12),
                    ),
                  ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.accentPink : AppTheme.primaryBlack,
                borderRadius: BorderRadius.circular(16),
                border: isMe ? null : Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message['user'],
                      style: TextStyle(
                        color: isMe ? AppTheme.white : AppTheme.accentPink,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (!isMe) const SizedBox(height: 4),
                  Text(
                    message['message'],
                    style: TextStyle(
                      color: isMe ? AppTheme.white : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message['time'],
                    style: TextStyle(
                      color: isMe ? AppTheme.white.withValues(alpha: 0.7) : AppTheme.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            // ProfileImageManager를 사용한 프로필 이미지 표시
            ProfileImageManager.instance.buildProfileImage(
              radius: 16,
              placeholder: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.accentPink,
                child: Text(
                  message['user'][0],
                  style: const TextStyle(color: AppTheme.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 채팅 메시지 전송
  void _sendChatMessage(
    String message,
    List<Map<String, dynamic>> chatMessages,
    StateSetter setState,
    TextEditingController controller,
  ) {
    if (message.trim().isEmpty) return;

    // 새 메시지 추가
    final newMessage = {
      'id': chatMessages.length + 1,
      'user': '락스타', // 현재 사용자
      'message': message.trim(),
      'time': _getCurrentTime(),
      'isMe': true,
    };

    setState(() {
      chatMessages.add(newMessage);
    });

    // 입력 필드 초기화
    controller.clear();

    // 시뮬레이션된 응답 메시지 (1-2초 후)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final responses = [
          '좋은 아이디어네요! 👍',
          '저도 동의합니다! 🎵',
          '멋진 연주였어요! 👏',
          '다음 곡은 뭐로 할까요? 🎼',
          '리듬이 정말 좋았어요! 🥁',
        ];
        
        final randomResponse = responses[DateTime.now().millisecond % responses.length];
        final responseMessage = {
          'id': chatMessages.length + 1,
          'user': 'GuitarHero3',
          'message': randomResponse,
          'time': _getCurrentTime(),
          'isMe': false,
        };

        setState(() {
          chatMessages.add(responseMessage);
        });
      }
    });
  }

  /// 현재 시간 포맷
  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  /// 파일 업로드 모달 표시
  void _showFileUploadModal(String type) async {
    setState(() {
      _uploadedMediaType = type;
      _uploadedMediaData = null;
    });

    try {
      XFile? pickedFile;
      switch (type) {
        case 'image':
          pickedFile = await _picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 85,
          );
          break;
        case 'video':
          pickedFile = await _picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 10),
          );
          break;
        case 'audio':
          pickedFile = await _picker.pickMedia();
          break;
      }

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _uploadedMediaData = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('파일 업로드 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 미디어 타입에 따른 아이콘 반환
  IconData _getMediaIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.music_note;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// 미디어 타입에 따른 텍스트 반환
  String _getMediaTypeText(String type) {
    switch (type) {
      case 'image':
        return '이미지';
      case 'video':
        return '비디오';
      case 'audio':
        return '오디오';
      default:
        return '파일';
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수
    
    // 탭 재진입 시 데이터 동기화 (안전장치)
    _syncDataFromAppStateManager();
    
    final filteredSessions = _filterJamSessions();
    
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        title: const Text('Jam 생성'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            itemBuilder: (context) => _filterOptions.map((filter) {
              return PopupMenuItem(
                value: filter,
                child: Text(filter),
              );
            }).toList(),
            child: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Jam 세션 검색...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear, color: AppTheme.grey),
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.secondaryBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // 필터 칩
          if (_selectedFilter != '전체')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text(_selectedFilter),
                    backgroundColor: AppTheme.accentPink,
                    labelStyle: const TextStyle(color: AppTheme.white),
                    deleteIcon: const Icon(Icons.close, color: AppTheme.white),
                    onDeleted: () {
                      setState(() {
                        _selectedFilter = '전체';
                      });
                    },
                  ),
                ],
              ),
            ),
          
          // Jam 세션 리스트
          Expanded(
            child: filteredSessions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredSessions.length,
                    itemBuilder: (context, index) {
                      return _buildJamSessionCard(context, filteredSessions[index]);
                    },
                  ),
          ),
        ],
      ),
      // Jam 생성 플로팅 액션 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: _showJamCreationModal,
        backgroundColor: AppTheme.accentPink,
        child: const Icon(
          Icons.add,
          color: AppTheme.white,
          size: 30,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 64,
            color: AppTheme.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? '검색 결과가 없습니다' : 'Jam 세션이 없습니다',
            style: TextStyle(
              color: AppTheme.grey.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
                ? '다른 검색어를 시도해보세요'
                : '첫 번째 Jam 세션을 만들어보세요!',
            style: TextStyle(
              color: AppTheme.grey.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJamSessionCard(BuildContext context, Map<String, dynamic> jamSession) {
    // 🔄 동적 참여자 수 계산
    final participantsList = List<Map<String, dynamic>>.from(jamSession['participantsList'] ?? []);
    final actualParticipants = participantsList.length;
    
    return Card(
      color: AppTheme.secondaryBlack,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showUserProfile(jamSession['createdBy']),
                  child: jamSession['createdBy'] == AuthStateManager.instance.userName
                      ? ProfileImageManager.instance.buildProfileImage(
                          radius: 20,
                          placeholder: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.accentPink,
                            child: const Icon(Icons.person, color: AppTheme.white, size: 20),
                          ),
                        )
                      : CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.accentPink,
                          child: const Icon(Icons.person, color: AppTheme.white, size: 20),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jamSession['title'],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showUserProfile(jamSession['createdBy']),
                        child: Text(
                          '${jamSession['createdBy']} • ${jamSession['createdAt']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 상태 표시
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(jamSession['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    jamSession['status'],
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 설명
            Text(
              jamSession['description'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.white,
              ),
            ),
            const SizedBox(height: 12),
            
            // 태그
            Wrap(
              spacing: 4,
              children: jamSession['tags'].take(3).map<Widget>((tag) {
                return Chip(
                  label: Text(
                    tag,
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: AppTheme.accentPink.withValues(alpha: 0.2),
                  labelStyle: const TextStyle(color: AppTheme.accentPink),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            
            // 정보 행
            Row(
              children: [
                Icon(Icons.music_note, size: 16, color: AppTheme.grey),
                const SizedBox(width: 4),
                Text(
                  jamSession['genre'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: AppTheme.grey),
                const SizedBox(width: 4),
                Text(
                  '$actualParticipants/${jamSession['maxParticipants']} 참여',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.music_note, size: 16, color: AppTheme.grey),
                const SizedBox(width: 4),
                Text(
                  jamSession['instruments'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 액션 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _joinJamSession(jamSession),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentPink,
                      side: const BorderSide(color: AppTheme.accentPink),
                    ),
                    child: const Text('참여 신청'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showJamDetails(jamSession),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink),
                    child: const Text('상세 보기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🚪 ========== 참여자 나가기/내보내기 기능 ==========

  /// 참여자 액션 버튼들 (나가기/내보내기)
  Widget _buildParticipantActionButtons(Map<String, dynamic> jamSession) {
    final currentUser = AuthStateManager.instance.userName;
    final participantsList = List<Map<String, dynamic>>.from(jamSession['participantsList'] ?? []);
    
    // 현재 사용자가 참여자인지 확인
    final currentParticipant = participantsList.firstWhere(
      (p) => p['name'] == currentUser,
      orElse: () => <String, dynamic>{},
    );
    
    final isParticipant = currentParticipant.isNotEmpty;
    final isHost = isParticipant && currentParticipant['role'] == '방장';
    
    if (!isParticipant) {
      return const SizedBox.shrink(); // 참여자가 아니면 버튼 숨김
    }
    
    return Column(
      children: [
        // 참여자 나가기 버튼 (방장이 아닌 경우에만)
        if (!isHost) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _leaveJamSession(jamSession),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.exit_to_app, color: Colors.red),
              label: const Text(
                '세션 나가기',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
        
        // 방장 전용: 참여자 관리 안내
        if (isHost) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accentPink.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: AppTheme.accentPink,
                  size: 24,
                ),
                const SizedBox(height: 8),
                const Text(
                  '방장 권한',
                  style: TextStyle(
                    color: AppTheme.accentPink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '참여자 목록에서 각 참여자를 길게 눌러서 내보내기할 수 있습니다.',
                  style: TextStyle(
                    color: AppTheme.grey,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 참여자 자진 나가기
  void _leaveJamSession(Map<String, dynamic> jamSession) {
    final currentUser = AuthStateManager.instance.userName;
    final participantsList = List<Map<String, dynamic>>.from(jamSession['participantsList'] ?? []);
    
    // 현재 사용자가 참여자인지 확인
    final participantIndex = participantsList.indexWhere((p) => p['name'] == currentUser);
    if (participantIndex == -1) {
      _showErrorDialog('참여하지 않은 세션입니다.');
      return;
    }
    
    // 방장은 나갈 수 없음
    final participant = participantsList[participantIndex];
    if (participant['role'] == '방장') {
      _showErrorDialog('방장은 세션을 나갈 수 없습니다. 세션을 삭제하거나 방장을 위임해주세요.');
      return;
    }
    
    // 확인 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('세션 나가기', style: TextStyle(color: AppTheme.white)),
        content: Text(
          '정말로 "${jamSession['title']}" 세션에서 나가시겠습니까?',
          style: const TextStyle(color: AppTheme.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소', style: TextStyle(color: AppTheme.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _executeLeaveJamSession(jamSession, participantIndex);
            },
            child: const Text('나가기', style: TextStyle(color: AppTheme.accentPink)),
          ),
        ],
      ),
    );
  }

  /// 참여자 나가기 실행
  void _executeLeaveJamSession(Map<String, dynamic> jamSession, int participantIndex) {
    setState(() {
      final participantsList = List<Map<String, dynamic>>.from(jamSession['participantsList'] ?? []);
      final leavingParticipant = participantsList[participantIndex];
      
      // participantsList에서 제거
      participantsList.removeAt(participantIndex);
      
      // 카운트 업데이트
      jamSession['participantsList'] = participantsList;
      jamSession['participants'] = participantsList.length;
      
      // 상태 업데이트 (모집 중으로 변경 가능)
      if (jamSession['status'] == '진행 중' && participantsList.length < jamSession['maxParticipants']) {
        jamSession['status'] = '모집 중';
      }
      
      print('🚪 참여자 나가기 완료: ${leavingParticipant['name']} (남은 인원: ${participantsList.length}명)');
    });
    _saveJamSessions();
    
    // 전체 잼 세션 목록 다시 로드하여 UI 즉시 업데이트
    _loadJamSessionsFromAppState();
    
    // 모달이 열려있다면 모달 내부도 강제로 업데이트
    if (Navigator.of(context).canPop()) {
      // 현재 모달을 닫고 새로운 모달로 교체
      Navigator.of(context).pop();
      _showJamDetails(jamSession);
    }
    
    _showSuccessDialog('세션에서 나갔습니다.');
  }

  /// 방장의 참여자 내보내기
  void _kickParticipant(Map<String, dynamic> jamSession, Map<String, dynamic> participant) {
    final currentUser = AuthStateManager.instance.userName;
    final participantsList = List<Map<String, dynamic>>.from(jamSession['participantsList'] ?? []);
    
    // 현재 사용자가 방장인지 확인
    final isHost = participantsList.any((p) => p['name'] == currentUser && p['role'] == '방장');
    if (!isHost) {
      _showErrorDialog('방장만 참여자를 내보낼 수 있습니다.');
      return;
    }
    
    // 자기 자신을 내보낼 수 없음
    if (participant['name'] == currentUser) {
      _showErrorDialog('자기 자신을 내보낼 수 없습니다.');
      return;
    }
    
    // 방장을 내보낼 수 없음
    if (participant['role'] == '방장') {
      _showErrorDialog('다른 방장을 내보낼 수 없습니다.');
      return;
    }
    
    // 확인 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('참여자 내보내기', style: TextStyle(color: AppTheme.white)),
        content: Text(
          '정말로 "${participant['name']}"님을 세션에서 내보내시겠습니까?',
          style: const TextStyle(color: AppTheme.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소', style: TextStyle(color: AppTheme.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _executeKickParticipant(jamSession, participant);
            },
            child: const Text('내보내기', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 참여자 내보내기 실행
  void _executeKickParticipant(Map<String, dynamic> jamSession, Map<String, dynamic> participant) {
    setState(() {
      final participantsList = List<Map<String, dynamic>>.from(jamSession['participantsList'] ?? []);
      
      // participantsList에서 제거
      participantsList.removeWhere((p) => p['name'] == participant['name']);
      
      // 카운트 업데이트
      jamSession['participantsList'] = participantsList;
      jamSession['participants'] = participantsList.length;
      
      // 상태 업데이트 (모집 중으로 변경 가능)
      if (jamSession['status'] == '진행 중' && participantsList.length < jamSession['maxParticipants']) {
        jamSession['status'] = '모집 중';
      }
      
      print('👑 참여자 내보내기 완료: ${participant['name']} (남은 인원: ${participantsList.length}명)');
    });
    _saveJamSessions();
    
    _showSuccessDialog('${participant['name']}님을 내보냈습니다.');
  }

  /// 에러 다이얼로그 표시
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('알림', style: TextStyle(color: AppTheme.white)),
        content: Text(message, style: const TextStyle(color: AppTheme.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인', style: TextStyle(color: AppTheme.accentPink)),
          ),
        ],
      ),
    );
  }

  /// AppStateManager에서 잼 세션 데이터 다시 로드
  void _loadJamSessionsFromAppState() {
    try {
      final jamState = AppStateManager.instance.jamState;
      final jamSessions = jamState['jamSessions'] as List<dynamic>? ?? [];
      
      setState(() {
        _recentJamSessions = jamSessions.cast<Map<String, dynamic>>();
      });
      
      print('🔄 잼 세션 데이터 다시 로드 완료: ${_recentJamSessions.length}개');
    } catch (e) {
      print('❌ 잼 세션 데이터 로드 실패: $e');
    }
  }
} 