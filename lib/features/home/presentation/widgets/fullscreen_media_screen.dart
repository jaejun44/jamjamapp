import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:chewie/chewie.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'dart:typed_data';

class FullscreenMediaScreen extends StatefulWidget {
  final String mediaType;
  final String? mediaUrl;
  final Uint8List? mediaData;
  final String title;
  final String author;

  const FullscreenMediaScreen({
    super.key,
    required this.mediaType,
    this.mediaUrl,
    this.mediaData,
    required this.title,
    required this.author,
  });

  @override
  State<FullscreenMediaScreen> createState() => _FullscreenMediaScreenState();
}

class _FullscreenMediaScreenState extends State<FullscreenMediaScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isInitialized = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  /// 플레이어 초기화
  Future<void> _initializePlayer() async {
    try {
      if (widget.mediaType == 'video') {
        await _initializeVideoPlayer();
      } else if (widget.mediaType == 'audio') {
        await _initializeAudioPlayer();
      } else {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('풀스크린 미디어 플레이어 초기화 오류: $e');
    }
  }

  /// 비디오 플레이어 초기화
  Future<void> _initializeVideoPlayer() async {
    if (widget.mediaData != null) {
      // 메모리에서 비디오 재생 (실제로는 임시 파일로 저장해야 함)
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _isInitialized = true;
      });
    } else if (widget.mediaUrl != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl!));
      await _videoController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        allowFullScreen: false, // 이미 풀스크린이므로 false
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.accentPink,
          handleColor: AppTheme.accentPink,
          backgroundColor: AppTheme.grey,
          bufferedColor: AppTheme.grey.withValues(alpha: 0.5),
        ),
      );
      
      setState(() {
        _isInitialized = true;
      });
    }
  }

  /// 오디오 플레이어 초기화
  Future<void> _initializeAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    
    if (widget.mediaData != null) {
      // 메모리에서 오디오 재생 (실제로는 임시 파일로 저장해야 함)
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _isInitialized = true;
        _duration = const Duration(minutes: 3, seconds: 45);
      });
    } else if (widget.mediaUrl != null) {
      await _audioPlayer!.setSourceUrl(widget.mediaUrl!);
      _duration = await _audioPlayer!.getDuration() ?? Duration.zero;
      
      _audioPlayer!.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });
      
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });
      
      setState(() {
        _isInitialized = true;
      });
    }
  }

  /// 재생/일시정지 토글
  void _togglePlayPause() {
    if (widget.mediaType == 'video') {
      if (_chewieController != null) {
        if (_isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
        setState(() {
          _isPlaying = !_isPlaying;
        });
      }
    } else if (widget.mediaType == 'audio') {
      if (_audioPlayer != null) {
        if (_isPlaying) {
          _audioPlayer!.pause();
        } else {
          _audioPlayer!.resume();
        }
      }
    }
  }

  /// 오디오 진행률 업데이트
  void _onSeekChanged(double value) {
    if (_audioPlayer != null && _duration.inMilliseconds > 0) {
      final newPosition = Duration(milliseconds: (value * _duration.inMilliseconds).round());
      _audioPlayer!.seek(newPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(),
            
            // 미디어 콘텐츠
            Expanded(
              child: _buildMediaContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// 헤더 빌드
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppTheme.white, size: 28),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.author,
                  style: const TextStyle(
                    color: AppTheme.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: 공유 기능
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('공유 기능 준비 중'),
                  backgroundColor: AppTheme.accentPink,
                ),
              );
            },
            icon: const Icon(Icons.share, color: AppTheme.white),
          ),
        ],
      ),
    );
  }

  /// 미디어 콘텐츠 빌드
  Widget _buildMediaContent() {
    if (!_isInitialized) {
      return _buildLoadingState();
    }

    switch (widget.mediaType) {
      case 'video':
        return _buildVideoPlayer();
      case 'audio':
        return _buildAudioPlayer();
      case 'image':
        return _buildImageViewer();
      default:
        return _buildPlaceholder();
    }
  }

  /// 로딩 상태
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.accentPink,
          ),
          SizedBox(height: 16),
          Text(
            '미디어 로딩 중...',
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 비디오 플레이어
  Widget _buildVideoPlayer() {
    if (_chewieController != null) {
      return Container(
        width: double.infinity,
        child: Chewie(controller: _chewieController!),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  /// 오디오 플레이어
  Widget _buildAudioPlayer() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 앨범 아트 (시뮬레이션)
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.accentPink.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentPink, width: 2),
            ),
            child: const Icon(
              Icons.music_note,
              size: 80,
              color: AppTheme.accentPink,
            ),
          ),
          const SizedBox(height: 32),
          
          // 제목
          Text(
            widget.title,
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // 아티스트
          Text(
            widget.author,
            style: const TextStyle(
              color: AppTheme.grey,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // 진행률 바
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.accentPink,
              inactiveTrackColor: AppTheme.grey.withValues(alpha: 0.3),
              thumbColor: AppTheme.accentPink,
              overlayColor: AppTheme.accentPink.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _duration.inMilliseconds > 0 
                ? _position.inMilliseconds / _duration.inMilliseconds 
                : 0.0,
              onChanged: _onSeekChanged,
            ),
          ),
          
          // 시간 표시
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(
                    color: AppTheme.grey,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(
                    color: AppTheme.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // 컨트롤 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  // 이전 트랙 (시뮬레이션)
                },
                icon: const Icon(Icons.skip_previous, color: AppTheme.grey, size: 32),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: AppTheme.accentPink,
                  size: 64,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  // 다음 트랙 (시뮬레이션)
                },
                icon: const Icon(Icons.skip_next, color: AppTheme.grey, size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 이미지 뷰어
  Widget _buildImageViewer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: InteractiveViewer(
        child: Center(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: AppTheme.accentPink.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentPink, width: 2),
            ),
            child: const Icon(
              Icons.image,
              size: 120,
              color: AppTheme.accentPink,
            ),
          ),
        ),
      ),
    );
  }

  /// 플레이스홀더
  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.mediaType == 'image' ? Icons.image :
            widget.mediaType == 'text' ? Icons.text_fields :
            Icons.music_note,
            size: 120,
            color: AppTheme.accentPink,
          ),
          const SizedBox(height: 16),
          Text(
            widget.mediaType == 'image' ? '이미지 뷰어' :
            widget.mediaType == 'text' ? '텍스트 뷰어' :
            '미디어 뷰어',
            style: const TextStyle(
              color: AppTheme.grey,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// 시간 포맷팅
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
} 