import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'user_profile_screen.dart';

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
  
  // 임시 Jam 세션 데이터
  final List<Map<String, dynamic>> _recentJamSessions = [
    {
      'title': '재즈 팝 퓨전 세션',
      'genre': '재즈, 팝',
      'instruments': '기타, 피아노, 드럼',
      'participants': 3,
      'status': '모집 중',
      'createdBy': 'JamMaster1',
      'createdAt': '2시간 전',
    },
    {
      'title': '락 밴드 오디션',
      'genre': '락',
      'instruments': '기타, 베이스, 드럼, 보컬',
      'participants': 5,
      'status': '진행 중',
      'createdBy': 'GuitarHero3',
      'createdAt': '1일 전',
    },
    {
      'title': '클래식 듀오',
      'genre': '클래식',
      'instruments': '피아노, 바이올린',
      'participants': 2,
      'status': '완료',
      'createdBy': 'Pianist4',
      'createdAt': '3일 전',
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _genreController.dispose();
    _instrumentsController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
      // 폼 초기화
      _titleController.clear();
      _genreController.clear();
      _instrumentsController.clear();
      _descriptionController.clear();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jam 생성'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Text(
              '새로운 Jam 세션을 만들어보세요!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '함께 음악을 만들고 싶은 음악인들을 찾아보세요.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.grey,
              ),
            ),
            const SizedBox(height: 32),
            
            // Jam 생성 폼
            _buildCreationForm(context),
            
            const SizedBox(height: 32),
            
            // 최근 Jam 세션
            Text(
              '최근 Jam 세션',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Jam 세션 리스트
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentJamSessions.length,
              itemBuilder: (context, index) {
                return _buildJamSessionCard(context, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreationForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jam 정보',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              
              // 제목
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Jam 제목',
                  hintText: '예: 재즈 팝 퓨전 세션',
                ),
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
                  hintText: '예: 재즈, 팝, 락',
                ),
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
                  hintText: '예: 기타, 베이스, 드럼',
                ),
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
                  hintText: 'Jam 세션에 대한 설명을 작성해주세요...',
                ),
              ),
              const SizedBox(height: 24),
              
              // 생성 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createJamSession,
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
        ),
      ),
    );
  }

  Widget _buildJamSessionCard(BuildContext context, int index) {
    final jamSession = _recentJamSessions[index];
    return Card(
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
                        style: Theme.of(context).textTheme.titleMedium,
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
              jamSession['description'] ?? '설명 없음',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            
            // 정보 행
            Row(
              children: [
                Icon(Icons.music_note, size: 16, color: AppTheme.grey),
                const SizedBox(width: 4),
                Text(
                  jamSession['genre'],
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: AppTheme.grey),
                const SizedBox(width: 4),
                Text(
                  '${jamSession['participants']}명 참여',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(Icons.music_note, size: 16, color: AppTheme.grey),
                const SizedBox(width: 4),
                Text(
                  jamSession['instruments'],
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 액션 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${jamSession['title']}에 참여 신청했습니다'),
                          backgroundColor: AppTheme.accentPink,
                        ),
                      );
                    },
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${jamSession['title']}의 상세 정보를 확인합니다'),
                          backgroundColor: AppTheme.accentPink,
                        ),
                      );
                    },
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

  Color _getStatusColor(String status) {
    switch (status) {
      case '모집 중':
        return Colors.orange;
      case '진행 중':
        return Colors.green;
      case '완료':
        return Colors.grey;
      default:
        return AppTheme.accentPink;
    }
  }
} 