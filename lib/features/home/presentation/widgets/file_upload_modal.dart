import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class FileUploadModal extends StatefulWidget {
  final String uploadType; // 'image', 'video', 'audio'
  final Function(String title, String content, Uint8List? mediaData)? onUploadComplete;

  const FileUploadModal({
    super.key,
    required this.uploadType,
    this.onUploadComplete,
  });

  @override
  State<FileUploadModal> createState() => _FileUploadModalState();
}

class _FileUploadModalState extends State<FileUploadModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _selectedFileName;
  String? _fileSize;
  Uint8List? _selectedFileData;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectFile() async {
    try {
      XFile? file;
      
      switch (widget.uploadType) {
        case 'image':
          file = await _picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 80,
          );
          break;
        case 'video':
          file = await _picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 10),
          );
          break;
        case 'audio':
          // 웹에서는 오디오 파일 선택이 제한적이므로 이미지로 대체
          file = await _picker.pickImage(
            source: ImageSource.gallery,
          );
          break;
      }
      
      if (file != null && mounted) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedFileName = file.name;
          _fileSize = '${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB';
          _selectedFileData = bytes;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getUploadTypeText()}이(가) 선택되었습니다'),
              backgroundColor: AppTheme.accentPink,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('파일 선택 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getUploadTypeText() {
    switch (widget.uploadType) {
      case 'image':
        return '이미지';
      case 'video':
        return '비디오';
      case 'audio':
        return '음원';
      default:
        return '파일';
    }
  }

  IconData _getUploadTypeIcon() {
    switch (widget.uploadType) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.music_note;
      default:
        return Icons.file_present;
    }
  }

  void _uploadFile() async {
    if (_selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getUploadTypeText()}을(를) 선택해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제목을 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    // 업로드 진행률 시뮬레이션
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() {
          _uploadProgress = i / 100;
        });
      }
    }

    setState(() {
      _isUploading = false;
    });

    if (mounted) {
      // 콜백 호출
      if (widget.onUploadComplete != null) {
        widget.onUploadComplete!(
          _titleController.text,
          _descriptionController.text,
          _selectedFileData,
        );
      }
      
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getUploadTypeText()}이(가) 업로드되었습니다!'),
          backgroundColor: AppTheme.accentPink,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.secondaryBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getUploadTypeIcon(),
                      color: AppTheme.accentPink,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_getUploadTypeText()} 업로드',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppTheme.white),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 파일 선택 영역
            GestureDetector(
              onTap: _isUploading ? null : _selectFile,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlack,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedFileName != null ? AppTheme.accentPink : AppTheme.grey,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedFileName != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getUploadTypeIcon(),
                            color: AppTheme.accentPink,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedFileName!,
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_fileSize != null)
                            Text(
                              _fileSize!,
                              style: const TextStyle(
                                color: AppTheme.grey,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getUploadTypeIcon(),
                            color: AppTheme.grey,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_getUploadTypeText()} 선택하기',
                            style: const TextStyle(
                              color: AppTheme.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '클릭하여 ${_getUploadTypeText()}을(를) 선택하세요',
                            style: const TextStyle(
                              color: AppTheme.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // 제목
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '업로드할 콘텐츠의 제목을 입력하세요',
              ),
            ),
            const SizedBox(height: 16),

            // 설명
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '설명',
                hintText: '콘텐츠에 대한 설명을 입력하세요',
              ),
            ),
            const SizedBox(height: 24),

            // 업로드 진행률
            if (_isUploading) ...[
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: AppTheme.grey,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentPink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_uploadProgress * 100).toInt()}% 업로드 중...',
                    style: const TextStyle(
                      color: AppTheme.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],

            // 업로드 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadFile,
                child: _isUploading
                    ? const SizedBox(
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                        ),
                      )
                    : Text('${_getUploadTypeText()} 업로드'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 