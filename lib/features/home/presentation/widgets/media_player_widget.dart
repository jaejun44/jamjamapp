import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:chewie/chewie.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'fullscreen_media_screen.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:convert';

class MediaPlayerWidget extends StatefulWidget {
  final String mediaType;
  final String? mediaUrl;
  final Uint8List? mediaData;
  final String title;

  const MediaPlayerWidget({
    super.key,
    required this.mediaType,
    this.mediaUrl,
    this.mediaData,
    required this.title,
  });

  @override
  State<MediaPlayerWidget> createState() => _MediaPlayerWidgetState();
}

class _MediaPlayerWidgetState extends State<MediaPlayerWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  AudioPlayer? _audioPlayer;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _isMuted = true; // ✅ 음향 제어: 기본적으로 음향 비활성화
  bool _isPlaying = false; // ✅ 재생 상태 추가
  Duration _duration = Duration.zero; // ✅ 재생 시간 추가
  Duration _position = Duration.zero; // ✅ 현재 위치 추가
  String? _blobUrl; // Blob URL 저장용 변수 추가

  @override
  void initState() {
    super.initState();
    _initializeMediaPlayer();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _audioPlayer?.dispose();
    
    // Blob URL 정리
    if (_blobUrl != null) {
      try {
        html.Url.revokeObjectUrl(_blobUrl!);
      } catch (e) {
        print('❌ Blob URL 정리 실패: $e');
      }
    }
    
    super.dispose();
  }

  /// 미디어 데이터를 Blob URL로 변환
  String? _createBlobUrl(Uint8List mediaData) {
    try {
      // Uint8List를 Blob으로 변환
      final blob = html.Blob([mediaData]);
      
      // Blob URL 생성
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      print('🎬 Blob URL 생성 완료: $url');
      return url;
    } catch (e) {
      print('❌ Blob URL 생성 실패: $e');
      return null;
    }
  }

  /// 비디오 플레이어 초기화
  Future<void> _initializeVideoPlayer() async {
    try {
      if (widget.mediaData != null) {
        print('🎬 비디오 데이터 감지: ${widget.mediaData!.length} bytes');
        
        // mediaData를 Blob URL로 변환
        final blobUrl = _createBlobUrl(widget.mediaData!);
        
        if (blobUrl != null) {
          _blobUrl = blobUrl; // Blob URL 저장
          
          // Blob URL을 사용하여 비디오 플레이어 초기화
          _videoController = VideoPlayerController.network(blobUrl);
          
          await _videoController!.initialize();
          
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: true, // ✅ 자동 재생 활성화
            looping: false,
            aspectRatio: _videoController!.value.aspectRatio,
            allowFullScreen: true,
            allowMuting: true,
            showControls: true,
            materialProgressColors: ChewieProgressColors(
              playedColor: AppTheme.accentPink,
              handleColor: AppTheme.accentPink,
              backgroundColor: AppTheme.grey,
              bufferedColor: AppTheme.lightGrey,
            ),
          );
          
          // ✅ 음향 제어: 기본적으로 음향 비활성화
          _videoController!.setVolume(0.0);
          
          // ✅ 음향 제어: 터치 시 음향 활성화를 위한 리스너 추가
          _videoController!.addListener(() {
            if (_videoController!.value.isInitialized && !_isMuted) {
              // 음향이 활성화된 상태에서만 볼륨 조절
              _videoController!.setVolume(1.0);
            }
          });
          
          setState(() {
            _isInitialized = true;
            _isLoading = false;
          });
          
          print('✅ 비디오 플레이어 초기화 완료');
        } else {
          throw Exception('Blob URL 생성 실패');
        }
      } else {
        // 미디어 데이터가 없는 경우 플레이스홀더 표시
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ 비디오 플레이어 초기화 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 오디오 플레이어 초기화
  Future<void> _initializeAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    
    if (widget.mediaData != null) {
      // 메모리에서 오디오 재생 (실제로는 임시 파일로 저장해야 함)
      // 여기서는 시뮬레이션
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

  /// 미디어 플레이어 초기화
  Future<void> _initializeMediaPlayer() async {
    try {
      if (widget.mediaType == 'video') {
        await _initializeVideoPlayer();
      } else if (widget.mediaType == 'audio') {
        await _initializeAudioPlayer();
      }
    } catch (e) {
      print('❌ 미디어 플레이어 초기화 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.accentPink,
          ),
        ),
      );
    }

    if (!_isInitialized || _chewieController == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, color: AppTheme.white, size: 48),
              SizedBox(height: 8),
              Text(
                '비디오를 불러올 수 없습니다',
                style: TextStyle(color: AppTheme.white),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // ✅ 터치 시 음향 활성화
        if (_isMuted) {
          setState(() {
            _isMuted = false;
          });
          _videoController?.setVolume(1.0);
          print('🔊 음향 활성화됨');
        }
      },
      child: Stack(
        children: [
          Chewie(controller: _chewieController!),
          // ✅ 음향 상태 표시 오버레이
          if (_isMuted)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.volume_off,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 로딩 상태
  Widget _buildLoadingState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.accentPink,
            ),
            SizedBox(height: 12),
            Text(
              '미디어 로딩 중...',
              style: TextStyle(
                color: AppTheme.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 비디오 플레이어
  Widget _buildVideoPlayer() {
    if (_chewieController != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Chewie(controller: _chewieController!),
            ),
            // 풀스크린 버튼
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _openFullscreen(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: AppTheme.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  /// 오디오 플레이어
  Widget _buildAudioPlayer() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // 제목과 풀스크린 버튼
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => _openFullscreen(),
                child: const Icon(
                  Icons.fullscreen,
                  color: AppTheme.grey,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 진행률 바
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.accentPink,
              inactiveTrackColor: AppTheme.grey.withValues(alpha: 0.3),
              thumbColor: AppTheme.accentPink,
              overlayColor: AppTheme.accentPink.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _duration.inMilliseconds > 0 
                ? _position.inMilliseconds / _duration.inMilliseconds 
                : 0.0,
              onChanged: _onSeekChanged,
            ),
          ),
          
          // 시간 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: const TextStyle(
                  color: AppTheme.grey,
                  fontSize: 12,
                ),
              ),
              Text(
                _formatDuration(_duration),
                style: const TextStyle(
                  color: AppTheme.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          // 컨트롤 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: AppTheme.accentPink,
                  size: 48,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 플레이스홀더 (이미지, 텍스트 등)
  Widget _buildPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.mediaType == 'image' ? Icons.image :
              widget.mediaType == 'text' ? Icons.text_fields :
              Icons.music_note,
              size: 48,
              color: AppTheme.accentPink,
            ),
            const SizedBox(height: 8),
            Text(
              widget.mediaType == 'image' ? '이미지 콘텐츠' :
              widget.mediaType == 'text' ? '텍스트 콘텐츠' :
              '미디어 콘텐츠',
              style: const TextStyle(
                color: AppTheme.grey,
                fontSize: 14,
              ),
            ),
            if (widget.mediaData != null)
              const Text(
                '미디어 데이터 포함',
                style: TextStyle(
                  color: AppTheme.accentPink,
                  fontSize: 12,
                ),
              ),
          ],
        ),
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

  /// 풀스크린 열기
  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenMediaScreen(
          mediaType: widget.mediaType,
          mediaUrl: widget.mediaUrl,
          mediaData: widget.mediaData,
          title: widget.title,
          author: '작성자', // 실제로는 피드에서 가져와야 함
        ),
      ),
    );
  }
} 