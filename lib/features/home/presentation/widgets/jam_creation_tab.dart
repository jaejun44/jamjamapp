import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'user_profile_screen.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class JamCreationTab extends StatefulWidget {
  const JamCreationTab({super.key});

  @override
  State<JamCreationTab> createState() => _JamCreationTabState();
}

class _JamCreationTabState extends State<JamCreationTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _genreController = TextEditingController();
  final _instrumentsController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isCreating = false;
  bool _isUploading = false;
  
  // 실시간 업데이트 상태
  Timer? _realtimeUpdateTimer;
  bool _isRealtimeUpdateEnabled = true;
  
  // 검색 및 필터 상태
  String _searchQuery = '';
  String _selectedFilter = '전체';
  final List<String> _filterOptions = ['전체', '모집 중', '진행 중', '완료'];
  
  // 업로드된 파일들
  List<Map<String, dynamic>> _uploadedFiles = [];
  
  // 이미지 피커
  final ImagePicker _picker = ImagePicker();

  // 임시 Jam 세션 데이터 (확장된 버전)
  final List<Map<String, dynamic>> _recentJamSessions = [
    {
      'id': 1,
      'title': '재즈 팝 퓨전 세션',
      'genre': '재즈, 팝',
      'instruments': '기타, 피아노, 드럼',
      'participants': 3,
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
    },
    {
      'id': 2,
      'title': '락 밴드 오디션',
      'genre': '락',
      'instruments': '기타, 베이스, 드럼, 보컬',
      'participants': 5,
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
    },
    {
      'id': 3,
      'title': '클래식 듀오',
      'genre': '클래식',
      'instruments': '피아노, 바이올린',
      'participants': 2,
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
    },
  ];

  // 참여 신청 대기 목록
  final List<Map<String, dynamic>> _pendingJoinRequests = [];

  @override
  void initState() {
    super.initState();
    _startRealtimeUpdates();
  }

  @override
  void dispose() {
    _realtimeUpdateTimer?.cancel();
    _titleController.dispose();
    _genreController.dispose();
    _instrumentsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 실시간 업데이트 시작
  void _startRealtimeUpdates() {
    _realtimeUpdateTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_isRealtimeUpdateEnabled && mounted) {
        _simulateJamUpdates();
      }
    });
  }

  /// Jam 업데이트 시뮬레이션
  void _simulateJamUpdates() {
    final random = DateTime.now().millisecondsSinceEpoch % _recentJamSessions.length;
    if (random < _recentJamSessions.length) {
      setState(() {
        final jam = _recentJamSessions[random];
        if (jam['status'] == '모집 중' && jam['participants'] < jam['maxParticipants']) {
          jam['participants'] = (jam['participants'] ?? 0) + 1;
          if (jam['participants'] >= jam['maxParticipants']) {
            jam['status'] = '진행 중';
          }
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
    // 방장인지 확인
    final isHost = jamSession['createdBy'] == '락스타';
    
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

  /// 참여 신청 제출
  void _submitJoinRequest(Map<String, dynamic> jamSession) {
    // 참여 신청 상태 업데이트
    setState(() {
      _pendingJoinRequests.add({
        'jamId': jamSession['id'],
        'jamTitle': jamSession['title'],
        'hostName': jamSession['createdBy'],
        'requestTime': DateTime.now(),
        'status': 'pending', // pending, approved, rejected
      });
    });

    _showSuccessDialog('참여 신청이 완료되었습니다! 방장의 승인을 기다려주세요. 🙏');
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
            Row(
              children: [
                Text(
                  request['requestTime'],
                  style: const TextStyle(color: AppTheme.grey, fontSize: 12),
                ),
                const Spacer(),
                if (isPending) ...[
                  TextButton(
                    onPressed: () {
                      setState(() {
                        request['status'] = 'rejected';
                      });
                      _showApprovalResult('거절', request['userName']);
                    },
                    child: const Text(
                      '거절',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        request['status'] = 'approved';
                      });
                      _showApprovalResult('승인', request['userName']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPink,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('승인'),
                  ),
                ],
              ],
            ),
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
                    const SizedBox(height: 16),
                    
                    // 파일 업로드
                    if (_uploadedFiles.isNotEmpty) ...[
                      Text(
                        '업로드된 파일',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(_uploadedFiles.map((file) => ListTile(
                        leading: Icon(
                          _getFileIcon(file['type']),
                          color: AppTheme.accentPink,
                        ),
                        title: Text(
                          file['name'],
                          style: const TextStyle(color: AppTheme.white),
                        ),
                        subtitle: Text(
                          file['size'],
                          style: const TextStyle(color: AppTheme.grey),
                        ),
                        trailing: IconButton(
                          onPressed: () {
                            setState(() {
                              _uploadedFiles.remove(file);
                            });
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ))),
                      const SizedBox(height: 16),
                    ],
                    
                    // 파일 업로드 버튼
                    OutlinedButton.icon(
                      onPressed: _isUploading ? null : _uploadFile,
                      icon: _isUploading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPink),
                              ),
                            )
                          : const Icon(Icons.upload_file),
                      label: Text(_isUploading ? '업로드 중...' : '파일 업로드'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentPink,
                        side: const BorderSide(color: AppTheme.accentPink),
                      ),
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    // Jam 세션 생성 시뮬레이션
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isCreating = false;
    });

    if (mounted) {
      // 새 Jam 세션 추가
      final newJamSession = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': _titleController.text,
        'genre': _genreController.text,
        'instruments': _instrumentsController.text,
        'participants': 1,
        'maxParticipants': 5,
        'status': '모집 중',
        'createdBy': '나',
        'createdAt': '방금 전',
        'description': _descriptionController.text,
        'tags': _genreController.text.split(',').map((e) => e.trim()).toList(),
        'isLive': false,
        'recordingUrl': null,
        'files': _uploadedFiles,
        'chat': [],
      };

      setState(() {
        _recentJamSessions.insert(0, newJamSession);
      });

      // 폼 초기화
      _titleController.clear();
      _genreController.clear();
      _instrumentsController.clear();
      _descriptionController.clear();
      _uploadedFiles.clear();

      Navigator.of(context).pop(); // 모달 닫기

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam 세션이 생성되었습니다!'),
          backgroundColor: AppTheme.accentPink,
        ),
      );
    }
  }

  void _showUserProfile(String username) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(username: username),
      ),
    );
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
    // 시뮬레이션된 참여자 데이터
    final List<Map<String, dynamic>> participants = [
      {
        'id': 1,
        'name': jamSession['createdBy'],
        'avatar': '👤',
        'role': '방장',
        'instruments': ['기타', '피아노'],
        'isOnline': true,
        'joinTime': '방금 전',
      },
      {
        'id': 2,
        'name': 'GuitarHero3',
        'avatar': '🎸',
        'role': '참여자',
        'instruments': ['기타'],
        'isOnline': true,
        'joinTime': '5분 전',
      },
      {
        'id': 3,
        'name': 'Drummer5',
        'avatar': '🥁',
        'role': '참여자',
        'instruments': ['드럼'],
        'isOnline': false,
        'joinTime': '10분 전',
      },
    ];

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
                '${jamSession['participants']}/${jamSession['maxParticipants']} 참여',
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
                return _buildParticipantCard(participant);
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
                  child: const Text('참여하기'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showJamChat(jamSession);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentPink,
                    side: const BorderSide(color: AppTheme.accentPink),
                  ),
                  child: const Text('채팅'),
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
        ],
      ),
    );
  }

  /// 참여자 카드 위젯
  Widget _buildParticipantCard(Map<String, dynamic> participant) {
    return Card(
      color: AppTheme.primaryBlack,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
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
        trailing: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
            _showUserProfile(participant['name']);
          },
          icon: const Icon(Icons.person, color: AppTheme.accentPink),
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
            CircleAvatar(
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
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.accentPink,
              child: Text(
                message['user'][0],
                style: const TextStyle(color: AppTheme.white, fontSize: 12),
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

  @override
  Widget build(BuildContext context) {
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
                  child: CircleAvatar(
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
                  '${jamSession['participants']}/${jamSession['maxParticipants']} 참여',
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
} 