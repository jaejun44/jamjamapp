import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/chat_service.dart';
import '../../../home/presentation/widgets/screens/user_profile_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final String userName;
  final String userAvatar;
  final String? otherUserId;

  const ChatRoomScreen({
    super.key,
    required this.userName,
    required this.userAvatar,
    this.otherUserId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Supabase 모드 (otherUserId 제공 시 활성화)
  String? _roomId;

  // 메시지 데이터 (Supabase 모드에서는 실제 데이터로 교체)
  final List<Map<String, dynamic>> _messages = [
    {
      'id': 1,
      'text': '안녕하세요! 함께 연주해요 🎵',
      'isMe': false,
      'timestamp': '오후 2:30',
      'type': 'text',
    },
    {
      'id': 2,
      'text': '네! 좋은 아이디어네요',
      'isMe': true,
      'timestamp': '오후 2:32',
      'type': 'text',
    },
    {
      'id': 3,
      'text': '어떤 장르로 연주하고 싶으세요?',
      'isMe': false,
      'timestamp': '오후 2:33',
      'type': 'text',
    },
    {
      'id': 4,
      'text': '재즈 팝 퓨전은 어떨까요?',
      'isMe': true,
      'timestamp': '오후 2:35',
      'type': 'text',
    },
    {
      'id': 5,
      'text': '좋아요! 제가 기타를 맡을게요 🎸',
      'isMe': false,
      'timestamp': '오후 2:36',
      'type': 'text',
    },
  ];

  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    if (widget.otherUserId != null) {
      _initSupabaseRoom(widget.otherUserId!);
    }
  }

  Future<void> _initSupabaseRoom(String otherUserId) async {
    final roomId = await ChatService.instance.getOrOpenRoom(otherUserId);
    if (roomId == null || !mounted) return;
    _roomId = roomId;

    final loaded = await ChatService.instance.loadMessages(roomId);
    if (!mounted) return;
    if (loaded.isNotEmpty) {
      setState(() {
        _messages
          ..clear()
          ..addAll(loaded);
      });
      _scrollToBottom();
    }

    ChatService.instance.subscribeToRoom(roomId, (message) {
      if (!mounted) return;
      setState(() => _messages.add(message));
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    if (_roomId != null) {
      ChatService.instance.unsubscribeFromRoom(_roomId!);
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    final newMessage = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'text': text,
      'isMe': true,
      'timestamp': _getCurrentTime(),
      'type': 'text',
    };

    setState(() {
      _messages.add(newMessage);
    });

    _messageController.clear();
    _scrollToBottom();

    if (_roomId != null) {
      // Supabase 모드: 비동기 전송 (로컬에 이미 추가됨)
      ChatService.instance.sendMessage(_roomId!, text);
    } else {
      // 시뮬레이션 모드
      _simulateTyping();
    }
  }

  void _simulateTyping() {
    setState(() {
      _isTyping = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });

        // 상대방 응답 시뮬레이션
        final responses = [
          '좋은 아이디어네요! 👍',
          '언제 연주할까요?',
          '저도 참여하고 싶어요!',
          '음악 파일 공유해드릴게요',
          '연습 영상 보내드릴게요 🎵',
        ];

        final randomResponse = responses[_messages.length % responses.length];
        final responseMessage = {
          'id': _messages.length + 1,
          'text': randomResponse,
          'isMe': false,
          'timestamp': _getCurrentTime(),
          'type': 'text',
        };

        setState(() {
          _messages.add(responseMessage);
        });

        _scrollToBottom();
      }
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 사용자 프로필로 이동
  void _showUserProfile(String username) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(username: username),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () => _showUserProfile(widget.userName),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.accentPink,
                child: Text(
                  widget.userAvatar,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _showUserProfile(widget.userName),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Text(
                    '온라인',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('음성 통화 기능 준비 중'),
                  backgroundColor: AppTheme.accentPink,
                ),
              );
            },
            icon: const Icon(Icons.call),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('영상 통화 기능 준비 중'),
                  backgroundColor: AppTheme.accentPink,
                ),
              );
            },
            icon: const Icon(Icons.videocam),
          ),
        ],
      ),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          // 타이핑 표시
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppTheme.accentPink,
                    child: Text(
                      widget.userAvatar,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBlack,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildTypingDot(0),
                        const SizedBox(width: 4),
                        _buildTypingDot(1),
                        const SizedBox(width: 4),
                        _buildTypingDot(2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // 메시지 입력
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.grey, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('첨부 파일 기능 준비 중'),
                        backgroundColor: AppTheme.accentPink,
                      ),
                    );
                  },
                  icon: const Icon(Icons.attach_file, color: AppTheme.grey),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(
                    Icons.send,
                    color: AppTheme.accentPink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message['isMe'] ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message['isMe']) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.accentPink,
              child: Text(
                widget.userAvatar,
                style: const TextStyle(fontSize: 10),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: message['isMe'] ? AppTheme.accentPink : AppTheme.secondaryBlack,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['text'],
                    style: TextStyle(
                      color: message['isMe'] ? AppTheme.white : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message['timestamp'],
                    style: TextStyle(
                      color: message['isMe'] ? AppTheme.white.withValues(alpha: 0.7) : AppTheme.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message['isMe']) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.accentPink,
              child: const Text(
                '나',
                style: TextStyle(fontSize: 10, color: AppTheme.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppTheme.accentPink,
            child: Text(
              widget.userAvatar,
              style: const TextStyle(fontSize: 10),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBlack,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 200)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppTheme.grey.withValues(alpha: value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
} 