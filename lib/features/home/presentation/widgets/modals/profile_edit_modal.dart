import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data'; // 웹 환경을 위해 Uint8List 사용

class ProfileEditModal extends StatefulWidget {
  final Function(Uint8List?, String?)? onImageChanged;
  final Function(String, String, String, String)? onProfileSaved;
  
  // 초기 데이터를 받는 매개변수들 추가
  final String? initialName;
  final String? initialNickname;
  final String? initialBio;
  final String? initialInstruments;

  const ProfileEditModal({
    super.key,
    this.onImageChanged,
    this.onProfileSaved,
    this.initialName,
    this.initialNickname,
    this.initialBio,
    this.initialInstruments,
  });

  @override
  State<ProfileEditModal> createState() => _ProfileEditModalState();
}

class _ProfileEditModalState extends State<ProfileEditModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _bioController;
  late final TextEditingController _instrumentController;
  
  bool _isSaving = false;
  bool _isImageUploading = false;
  Uint8List? _profileImageBytes; // 프로필 이미지 바이트 데이터
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 초기 데이터로 컨트롤러 초기화
    _nameController = TextEditingController(text: widget.initialName ?? 'JamMaster1');
    _nicknameController = TextEditingController(text: widget.initialNickname ?? 'jam_master');
    _bioController = TextEditingController(text: widget.initialBio ?? '재즈와 팝을 사랑하는 음악인입니다 🎵');
    _instrumentController = TextEditingController(text: widget.initialInstruments ?? '기타, 피아노');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _bioController.dispose();
    _instrumentController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    // 프로필 저장 시뮬레이션
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    // 프로필 데이터를 부모 위젯에 전달
    if (widget.onProfileSaved != null) {
      final String name = _nameController.text.trim();
      final String nickname = _nicknameController.text.trim();
      final String bio = _bioController.text.trim();
      final String instruments = _instrumentController.text.trim();
      
      widget.onProfileSaved!(name, nickname, bio, instruments);
    }

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('프로필이 저장되었습니다!'),
        backgroundColor: AppTheme.accentPink,
      ),
    );
  }

  void _uploadImage() async {
    setState(() {
      _isImageUploading = true;
    });
    final messenger = ScaffoldMessenger.of(context);

    try {
      // 실제 이미지 선택
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );
      
      if (image != null && mounted) {
        // 웹 환경에서는 XFile에서 직접 바이트 데이터를 읽어옴
        final Uint8List imageBytes = await image.readAsBytes();
        final String imageName = image.name;
        
        
        setState(() {
          _profileImageBytes = imageBytes;
          _isImageUploading = false;
        });
        
        // 부모 위젯에 이미지 변경 알림
        if (widget.onImageChanged != null) {
          widget.onImageChanged!(imageBytes, imageName);
        }
        
        messenger.showSnackBar(
          const SnackBar(
            content: Text('프로필 이미지가 업로드되었습니다!'),
            backgroundColor: AppTheme.accentPink,
          ),
        );
      } else if (mounted) {
        setState(() {
          _isImageUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImageUploading = false;
        });

        messenger.showSnackBar(
          SnackBar(
            content: Text('이미지 업로드 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '프로필 편집',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppTheme.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 프로필 이미지
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.accentPink,
                      backgroundImage: _profileImageBytes != null 
                          ? MemoryImage(_profileImageBytes!) 
                          : null,
                      child: _profileImageBytes == null
                          ? const Icon(Icons.person, color: AppTheme.white, size: 50)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.accentPink,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isImageUploading ? null : _uploadImage,
                          icon: _isImageUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                  ),
                                )
                              : const Icon(Icons.camera_alt, color: AppTheme.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 이름
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '이름',
                  hintText: '실명을 입력하세요',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 닉네임
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: '닉네임',
                  hintText: '사용할 닉네임을 입력하세요',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '닉네임을 입력해주세요';
                  }
                  if (value.length < 2) {
                    return '닉네임은 2자 이상이어야 합니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 소개
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '소개',
                  hintText: '자신을 소개해주세요',
                ),
              ),
              const SizedBox(height: 16),

              // 악기
              TextFormField(
                controller: _instrumentController,
                decoration: const InputDecoration(
                  labelText: '주요 악기',
                  hintText: '예: 기타, 피아노, 드럼',
                ),
              ),
              const SizedBox(height: 24),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                          ),
                        )
                      : const Text('저장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 