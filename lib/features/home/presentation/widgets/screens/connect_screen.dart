import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/connect_service.dart';
import '../shared/musician_card_widget.dart';

/// Connect(매칭) 화면 — 추천 뮤지션 카드 순서대로 좋아요/패스
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  List<Map<String, dynamic>> _candidates = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    final candidates = await ConnectService.instance.getCandidates();
    if (!mounted) return;
    setState(() {
      _candidates = candidates;
      _currentIndex = 0;
      _isLoading = false;
    });
  }

  Future<void> _handleLike() async {
    if (_currentIndex >= _candidates.length) return;
    final target = _candidates[_currentIndex];
    final toId = target['userId'] as String;

    final matched = await ConnectService.instance.like(toId);

    if (!mounted) return;
    if (matched) {
      _showMatchDialog(target);
    }
    setState(() => _currentIndex++);
  }

  void _handlePass() {
    if (_currentIndex >= _candidates.length) return;
    setState(() => _currentIndex++);
  }

  void _showMatchDialog(Map<String, dynamic> user) {
    final nickname = user['nickname'] as String? ?? 'Unknown';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🎵 매칭 성사!',
          style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          '$nickname님과 연결되었습니다!\n채팅을 시작해보세요.',
          style: const TextStyle(color: AppTheme.grey),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('확인', style: TextStyle(color: AppTheme.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        title: const Text(
          'Connect',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentPink),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_candidates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, color: AppTheme.grey, size: 64),
            SizedBox(height: 16),
            Text(
              '추천할 뮤지션이 없습니다',
              style: TextStyle(color: AppTheme.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_currentIndex >= _candidates.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppTheme.accentPink, size: 64),
            const SizedBox(height: 16),
            const Text(
              '모든 추천 뮤지션을 확인했습니다!',
              style: TextStyle(color: AppTheme.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _loadCandidates();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('새로고침',
                  style: TextStyle(color: AppTheme.white)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: MusicianCardWidget(
        user: _candidates[_currentIndex],
        onLike: _handleLike,
        onPass: _handlePass,
      ),
    );
  }
}
