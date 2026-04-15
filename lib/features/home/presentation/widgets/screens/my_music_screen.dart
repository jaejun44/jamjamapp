import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';

class MyMusicScreen extends StatefulWidget {
  const MyMusicScreen({super.key});

  @override
  State<MyMusicScreen> createState() => _MyMusicScreenState();
}

class _MyMusicScreenState extends State<MyMusicScreen> {
  List<Map<String, dynamic>> _myMusic = [];
  bool _isLoading = true;
  String _selectedFilter = '전체';
  String _selectedSort = '최신순';

  @override
  void initState() {
    super.initState();
    _loadMyMusic();
  }

  Future<void> _loadMyMusic() async {
    // 시뮬레이션된 로딩
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _myMusic = [
        {
          'id': '1',
          'title': 'Jazz Night',
          'genre': '재즈',
          'duration': '3:45',
          'uploadDate': '2024-11-30',
          'plays': 1250,
          'likes': 89,
          'comments': 23,
          'thumbnail': null,
          'audioUrl': 'jazz_night.mp3',
          'description': '밤에 연주한 재즈 곡입니다.',
          'tags': ['재즈', '피아노', '밤'],
        },
        {
          'id': '2',
          'title': 'Rock Jam Session',
          'genre': '락',
          'duration': '5:20',
          'uploadDate': '2024-11-28',
          'plays': 2100,
          'likes': 156,
          'comments': 45,
          'thumbnail': null,
          'audioUrl': 'rock_jam.mp3',
          'description': '친구들과 함께한 락 잼 세션입니다.',
          'tags': ['락', '기타', '드럼'],
        },
        {
          'id': '3',
          'title': 'Pop Cover - Shape of You',
          'genre': '팝',
          'duration': '4:15',
          'uploadDate': '2024-11-25',
          'plays': 890,
          'likes': 67,
          'comments': 12,
          'thumbnail': null,
          'audioUrl': 'shape_of_you_cover.mp3',
          'description': 'Ed Sheeran의 Shape of You 커버입니다.',
          'tags': ['팝', '커버', '어쿠스틱'],
        },
        {
          'id': '4',
          'title': 'Classical Piano Sonata',
          'genre': '클래식',
          'duration': '8:30',
          'uploadDate': '2024-11-20',
          'plays': 450,
          'likes': 34,
          'comments': 8,
          'thumbnail': null,
          'audioUrl': 'piano_sonata.mp3',
          'description': '베토벤 피아노 소나타 연주입니다.',
          'tags': ['클래식', '피아노', '베토벤'],
        },
        {
          'id': '5',
          'title': 'Electronic Beat',
          'genre': '일렉트로닉',
          'duration': '6:45',
          'uploadDate': '2024-11-18',
          'plays': 3200,
          'likes': 234,
          'comments': 67,
          'thumbnail': null,
          'audioUrl': 'electronic_beat.mp3',
          'description': 'DAW로 만든 일렉트로닉 비트입니다.',
          'tags': ['일렉트로닉', '비트', 'DAW'],
        },
      ];
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredMusic {
    List<Map<String, dynamic>> filtered = List.from(_myMusic);
    
    // 필터 적용
    if (_selectedFilter != '전체') {
      filtered = filtered.where((music) => music['genre'] == _selectedFilter).toList();
    }
    
    // 정렬 적용
    switch (_selectedSort) {
      case '최신순':
        filtered.sort((a, b) => b['uploadDate'].compareTo(a['uploadDate']));
        break;
      case '오래된순':
        filtered.sort((a, b) => a['uploadDate'].compareTo(b['uploadDate']));
        break;
      case '인기순':
        filtered.sort((a, b) => b['plays'].compareTo(a['plays']));
        break;
      case '좋아요순':
        filtered.sort((a, b) => b['likes'].compareTo(a['likes']));
        break;
      case '제목순':
        filtered.sort((a, b) => a['title'].compareTo(b['title']));
        break;
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 음악'),
        backgroundColor: AppTheme.secondaryBlack,
        foregroundColor: AppTheme.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showUploadDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentPink))
                : _buildMusicList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterDropdown(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSortDropdown(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedFilter,
      decoration: const InputDecoration(
        labelText: '필터',
        labelStyle: TextStyle(color: AppTheme.grey),
        border: OutlineInputBorder(),
      ),
      dropdownColor: AppTheme.secondaryBlack,
      style: const TextStyle(color: AppTheme.white),
      items: ['전체', '재즈', '락', '팝', '클래식', '일렉트로닉'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: const TextStyle(color: AppTheme.white)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedFilter = newValue!;
        });
      },
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSort,
      decoration: const InputDecoration(
        labelText: '정렬',
        labelStyle: TextStyle(color: AppTheme.grey),
        border: OutlineInputBorder(),
      ),
      dropdownColor: AppTheme.secondaryBlack,
      style: const TextStyle(color: AppTheme.white),
      items: ['최신순', '오래된순', '인기순', '좋아요순', '제목순'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: const TextStyle(color: AppTheme.white)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedSort = newValue!;
        });
      },
    );
  }

  Widget _buildMusicList() {
    final filteredMusic = _filteredMusic;
    
    if (filteredMusic.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 64, color: AppTheme.grey),
            SizedBox(height: 16),
            Text(
              '업로드한 음악이 없습니다',
              style: TextStyle(color: AppTheme.grey, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              '첫 번째 음악을 업로드해보세요!',
              style: TextStyle(color: AppTheme.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredMusic.length,
      itemBuilder: (context, index) {
        final music = filteredMusic[index];
        return _buildMusicCard(music);
      },
    );
  }

  Widget _buildMusicCard(Map<String, dynamic> music) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.accentPink,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.music_note, color: AppTheme.white, size: 30),
        ),
        title: Text(
          music['title'],
          style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${music['genre']} • ${music['duration']} • ${music['uploadDate']}',
              style: const TextStyle(color: AppTheme.grey),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.play_arrow, size: 16, color: AppTheme.grey),
                Text(' ${music['plays']}', style: const TextStyle(color: AppTheme.grey)),
                const SizedBox(width: 16),
                Icon(Icons.favorite, size: 16, color: AppTheme.grey),
                Text(' ${music['likes']}', style: const TextStyle(color: AppTheme.grey)),
                const SizedBox(width: 16),
                Icon(Icons.comment, size: 16, color: AppTheme.grey),
                Text(' ${music['comments']}', style: const TextStyle(color: AppTheme.grey)),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.grey),
          onSelected: (value) => _handleMusicAction(value, music),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play',
              child: Row(
                children: [
                  Icon(Icons.play_arrow, color: AppTheme.accentPink),
                  SizedBox(width: 8),
                  Text('재생'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppTheme.accentPink),
                  SizedBox(width: 8),
                  Text('편집'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, color: AppTheme.accentPink),
                  SizedBox(width: 8),
                  Text('공유'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('삭제', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showMusicDetail(music),
      ),
    );
  }

  void _handleMusicAction(String action, Map<String, dynamic> music) {
    switch (action) {
      case 'play':
        _playMusic(music);
        break;
      case 'edit':
        _editMusic(music);
        break;
      case 'share':
        _shareMusic(music);
        break;
      case 'delete':
        _deleteMusic(music);
        break;
    }
  }

  void _playMusic(Map<String, dynamic> music) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: Text('${music['title']} 재생', style: const TextStyle(color: AppTheme.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.accentPink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.music_note, color: AppTheme.white, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              '재생 중...',
              style: const TextStyle(color: AppTheme.white),
            ),
            const SizedBox(height: 8),
            Text(
              '${music['duration']} • ${music['genre']}',
              style: const TextStyle(color: AppTheme.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기', style: TextStyle(color: AppTheme.accentPink)),
          ),
        ],
      ),
    );
  }

  void _editMusic(Map<String, dynamic> music) {
    final titleController = TextEditingController(text: music['title']);
    final descriptionController = TextEditingController(text: music['description']);
    String selectedGenre = music['genre'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: Text('${music['title']} 편집', style: const TextStyle(color: AppTheme.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: '제목',
                labelStyle: TextStyle(color: AppTheme.grey),
              ),
              controller: titleController,
              style: const TextStyle(color: AppTheme.white),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: '설명',
                labelStyle: TextStyle(color: AppTheme.grey),
              ),
              controller: descriptionController,
              style: const TextStyle(color: AppTheme.white),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '장르',
                labelStyle: TextStyle(color: AppTheme.grey),
              ),
              value: selectedGenre,
              dropdownColor: AppTheme.secondaryBlack,
              style: const TextStyle(color: AppTheme.white),
              items: ['재즈', '락', '팝', '클래식', '일렉트로닉'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(color: AppTheme.white)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                selectedGenre = newValue!;
              },
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
              // 실제로 음악 정보를 업데이트
              setState(() {
                final index = _myMusic.indexWhere((item) => item['id'] == music['id']);
                if (index != -1) {
                  _myMusic[index]['title'] = titleController.text;
                  _myMusic[index]['description'] = descriptionController.text;
                  _myMusic[index]['genre'] = selectedGenre;
                }
              });
              
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('음악이 수정되었습니다'),
                  backgroundColor: AppTheme.accentPink,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _shareMusic(Map<String, dynamic> music) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: Text('${music['title']} 공유', style: const TextStyle(color: AppTheme.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '공유 방법을 선택하세요:',
              style: TextStyle(color: AppTheme.white),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(Icons.copy, '링크 복사'),
                _buildShareOption(Icons.share, '공유'),
                _buildShareOption(Icons.download, '다운로드'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소', style: TextStyle(color: AppTheme.accentPink)),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: AppTheme.accentPink),
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label 완료'),
                backgroundColor: AppTheme.accentPink,
              ),
            );
          },
        ),
        Text(label, style: const TextStyle(color: AppTheme.grey, fontSize: 12)),
      ],
    );
  }

  void _deleteMusic(Map<String, dynamic> music) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('음악 삭제', style: TextStyle(color: AppTheme.white)),
        content: Text(
          '${music['title']}을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
          style: const TextStyle(color: AppTheme.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소', style: TextStyle(color: AppTheme.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _myMusic.removeWhere((item) => item['id'] == music['id']);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('음악이 삭제되었습니다'),
                  backgroundColor: AppTheme.accentPink,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showMusicDetail(Map<String, dynamic> music) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: Text(music['title'], style: const TextStyle(color: AppTheme.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.accentPink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.music_note, color: AppTheme.white, size: 60),
            ),
            const SizedBox(height: 16),
            Text('장르: ${music['genre']}', style: const TextStyle(color: AppTheme.white)),
            Text('길이: ${music['duration']}', style: const TextStyle(color: AppTheme.white)),
            Text('업로드: ${music['uploadDate']}', style: const TextStyle(color: AppTheme.white)),
            Text('재생: ${music['plays']}회', style: const TextStyle(color: AppTheme.white)),
            Text('좋아요: ${music['likes']}개', style: const TextStyle(color: AppTheme.white)),
            Text('댓글: ${music['comments']}개', style: const TextStyle(color: AppTheme.white)),
            const SizedBox(height: 8),
            Text('설명:', style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
            Text(music['description'], style: const TextStyle(color: AppTheme.grey)),
            const SizedBox(height: 8),
            Text('태그:', style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: (music['tags'] as List?)?.cast<String>().map((tag) => Chip(
                label: Text(tag, style: const TextStyle(color: AppTheme.white)),
                backgroundColor: AppTheme.accentPink,
              )).toList() ?? [],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기', style: TextStyle(color: AppTheme.accentPink)),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('음악 업로드', style: TextStyle(color: AppTheme.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '업로드할 음악 파일을 선택하세요',
              style: TextStyle(color: AppTheme.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('음악 업로드 기능은 백엔드 연동 후 구현됩니다'),
                    backgroundColor: AppTheme.accentPink,
                  ),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('파일 선택'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink),
            ),
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
} 