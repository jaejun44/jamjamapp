import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  // 알림 설정
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _jamInvitations = true;
  bool _newFollowers = true;
  bool _likesAndComments = true;
  
  // 개인정보 설정
  bool _profilePublic = true;
  bool _showOnlineStatus = true;
  bool _allowMessages = true;
  bool _showEmail = false;
  
  // 보안 설정
  bool _twoFactorAuth = false;
  bool _loginAlerts = true;
  
  // 계정 설정
  String _language = '한국어';
  String _theme = '다크';
  bool _autoPlay = true;
  bool _highQuality = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _pushNotifications = prefs.getBool('pushNotifications') ?? true;
      _emailNotifications = prefs.getBool('emailNotifications') ?? false;
      _jamInvitations = prefs.getBool('jamInvitations') ?? true;
      _newFollowers = prefs.getBool('newFollowers') ?? true;
      _likesAndComments = prefs.getBool('likesAndComments') ?? true;
      
      _profilePublic = prefs.getBool('profilePublic') ?? true;
      _showOnlineStatus = prefs.getBool('showOnlineStatus') ?? true;
      _allowMessages = prefs.getBool('allowMessages') ?? true;
      _showEmail = prefs.getBool('showEmail') ?? false;
      
      _twoFactorAuth = prefs.getBool('twoFactorAuth') ?? false;
      _loginAlerts = prefs.getBool('loginAlerts') ?? true;
      
      _language = prefs.getString('language') ?? '한국어';
      _theme = prefs.getString('theme') ?? '다크';
      _autoPlay = prefs.getBool('autoPlay') ?? true;
      _highQuality = prefs.getBool('highQuality') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('pushNotifications', _pushNotifications);
    await prefs.setBool('emailNotifications', _emailNotifications);
    await prefs.setBool('jamInvitations', _jamInvitations);
    await prefs.setBool('newFollowers', _newFollowers);
    await prefs.setBool('likesAndComments', _likesAndComments);
    
    await prefs.setBool('profilePublic', _profilePublic);
    await prefs.setBool('showOnlineStatus', _showOnlineStatus);
    await prefs.setBool('allowMessages', _allowMessages);
    await prefs.setBool('showEmail', _showEmail);
    
    await prefs.setBool('twoFactorAuth', _twoFactorAuth);
    await prefs.setBool('loginAlerts', _loginAlerts);
    
    await prefs.setString('language', _language);
    await prefs.setString('theme', _theme);
    await prefs.setBool('autoPlay', _autoPlay);
    await prefs.setBool('highQuality', _highQuality);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('설정이 저장되었습니다'),
        backgroundColor: AppTheme.accentPink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: AppTheme.secondaryBlack,
        foregroundColor: AppTheme.white,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('저장', style: TextStyle(color: AppTheme.accentPink)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildNotificationSettings(),
            _buildPrivacySettings(),
            _buildSecuritySettings(),
            _buildAccountSettings(),
            _buildSupportSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSection(
      title: '알림 설정',
      icon: Icons.notifications,
      children: [
        _buildSwitchTile(
          title: '푸시 알림',
          subtitle: '새로운 알림을 받습니다',
          value: _pushNotifications,
          onChanged: (value) => setState(() => _pushNotifications = value),
        ),
        _buildSwitchTile(
          title: '이메일 알림',
          subtitle: '이메일로 알림을 받습니다',
          value: _emailNotifications,
          onChanged: (value) => setState(() => _emailNotifications = value),
        ),
        _buildSwitchTile(
          title: 'Jam 초대',
          subtitle: 'Jam 세션 초대를 받습니다',
          value: _jamInvitations,
          onChanged: (value) => setState(() => _jamInvitations = value),
        ),
        _buildSwitchTile(
          title: '새 팔로워',
          subtitle: '새로운 팔로워 알림을 받습니다',
          value: _newFollowers,
          onChanged: (value) => setState(() => _newFollowers = value),
        ),
        _buildSwitchTile(
          title: '좋아요 및 댓글',
          subtitle: '좋아요와 댓글 알림을 받습니다',
          value: _likesAndComments,
          onChanged: (value) => setState(() => _likesAndComments = value),
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return _buildSection(
      title: '개인정보 보호',
      icon: Icons.privacy_tip,
      children: [
        _buildSwitchTile(
          title: '공개 프로필',
          subtitle: '다른 사용자가 내 프로필을 볼 수 있습니다',
          value: _profilePublic,
          onChanged: (value) => setState(() => _profilePublic = value),
        ),
        _buildSwitchTile(
          title: '온라인 상태 표시',
          subtitle: '다른 사용자에게 온라인 상태를 보여줍니다',
          value: _showOnlineStatus,
          onChanged: (value) => setState(() => _showOnlineStatus = value),
        ),
        _buildSwitchTile(
          title: '메시지 허용',
          subtitle: '다른 사용자로부터 메시지를 받습니다',
          value: _allowMessages,
          onChanged: (value) => setState(() => _allowMessages = value),
        ),
        _buildSwitchTile(
          title: '이메일 공개',
          subtitle: '다른 사용자에게 이메일을 보여줍니다',
          value: _showEmail,
          onChanged: (value) => setState(() => _showEmail = value),
        ),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    return _buildSection(
      title: '보안',
      icon: Icons.security,
      children: [
        _buildSwitchTile(
          title: '2단계 인증',
          subtitle: '계정 보안을 강화합니다',
          value: _twoFactorAuth,
          onChanged: (value) => setState(() => _twoFactorAuth = value),
        ),
        _buildSwitchTile(
          title: '로그인 알림',
          subtitle: '새로운 기기에서 로그인 시 알림을 받습니다',
          value: _loginAlerts,
          onChanged: (value) => setState(() => _loginAlerts = value),
        ),
        _buildListTile(
          title: '비밀번호 변경',
          subtitle: '계정 비밀번호를 변경합니다',
          icon: Icons.lock,
          onTap: () => _showChangePasswordDialog(),
        ),
        _buildListTile(
          title: '로그인 기록',
          subtitle: '최근 로그인 기록을 확인합니다',
          icon: Icons.history,
          onTap: () => _showLoginHistory(),
        ),
      ],
    );
  }

  Widget _buildAccountSettings() {
    return _buildSection(
      title: '계정 설정',
      icon: Icons.settings,
      children: [
        _buildListTile(
          title: '언어',
          subtitle: _language,
          icon: Icons.language,
          onTap: () => _showLanguageDialog(),
        ),
        _buildListTile(
          title: '테마',
          subtitle: _theme,
          icon: Icons.palette,
          onTap: () => _showThemeDialog(),
        ),
        _buildSwitchTile(
          title: '자동 재생',
          subtitle: '미디어 콘텐츠를 자동으로 재생합니다',
          value: _autoPlay,
          onChanged: (value) => setState(() => _autoPlay = value),
        ),
        _buildSwitchTile(
          title: '고화질',
          subtitle: '고화질 미디어를 사용합니다 (데이터 사용량 증가)',
          value: _highQuality,
          onChanged: (value) => setState(() => _highQuality = value),
        ),
        _buildListTile(
          title: '데이터 사용량',
          subtitle: '앱 데이터 사용량을 확인합니다',
          icon: Icons.data_usage,
          onTap: () => _showDataUsage(),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSection(
      title: '지원',
      icon: Icons.help,
      children: [
        _buildListTile(
          title: '도움말',
          subtitle: '앱 사용법을 확인합니다',
          icon: Icons.help_outline,
          onTap: () => _showHelp(),
        ),
        _buildListTile(
          title: '문의하기',
          subtitle: '개발팀에 문의합니다',
          icon: Icons.email,
          onTap: () => _showContact(),
        ),
        _buildListTile(
          title: '버그 신고',
          subtitle: '발견한 버그를 신고합니다',
          icon: Icons.bug_report,
          onTap: () => _showBugReport(),
        ),
        _buildListTile(
          title: '개인정보 처리방침',
          subtitle: '개인정보 처리방침을 확인합니다',
          icon: Icons.privacy_tip_outlined,
          onTap: () => _showPrivacyPolicy(),
        ),
        _buildListTile(
          title: '이용약관',
          subtitle: '서비스 이용약관을 확인합니다',
          icon: Icons.description,
          onTap: () => _showTermsOfService(),
        ),
        _buildListTile(
          title: '앱 정보',
          subtitle: 'JamJam v1.0.0',
          icon: Icons.info,
          onTap: () => _showAppInfo(),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.accentPink),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: AppTheme.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.grey)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accentPink,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accentPink),
      title: Text(title, style: const TextStyle(color: AppTheme.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.grey)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.grey),
      onTap: onTap,
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('비밀번호 변경', style: TextStyle(color: AppTheme.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: '현재 비밀번호',
                labelStyle: TextStyle(color: AppTheme.grey),
              ),
              obscureText: true,
              style: const TextStyle(color: AppTheme.white),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: '새 비밀번호',
                labelStyle: TextStyle(color: AppTheme.grey),
              ),
              obscureText: true,
              style: const TextStyle(color: AppTheme.white),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: '새 비밀번호 확인',
                labelStyle: TextStyle(color: AppTheme.grey),
              ),
              obscureText: true,
              style: const TextStyle(color: AppTheme.white),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('비밀번호가 변경되었습니다'),
                  backgroundColor: AppTheme.accentPink,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink),
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('언어 선택', style: TextStyle(color: AppTheme.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('한국어', '한국어'),
            _buildLanguageOption('English', '영어'),
            _buildLanguageOption('日本語', '일본어'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String title, String value) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: AppTheme.white)),
      trailing: _language == value ? const Icon(Icons.check, color: AppTheme.accentPink) : null,
      onTap: () {
        setState(() => _language = value);
        Navigator.of(context).pop();
      },
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('테마 선택', style: TextStyle(color: AppTheme.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('다크', '다크'),
            _buildThemeOption('라이트', '라이트'),
            _buildThemeOption('시스템', '시스템'),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String title, String value) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: AppTheme.white)),
      trailing: _theme == value ? const Icon(Icons.check, color: AppTheme.accentPink) : null,
      onTap: () {
        setState(() => _theme = value);
        Navigator.of(context).pop();
      },
    );
  }

  void _showLoginHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('로그인 기록', style: TextStyle(color: AppTheme.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('최근 로그인 기록:', style: TextStyle(color: AppTheme.white)),
            SizedBox(height: 8),
            Text('• 2024-12-01 14:30 - Chrome (현재)', style: TextStyle(color: AppTheme.grey)),
            Text('• 2024-11-30 09:15 - iPhone', style: TextStyle(color: AppTheme.grey)),
            Text('• 2024-11-29 18:45 - Android', style: TextStyle(color: AppTheme.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인', style: TextStyle(color: AppTheme.accentPink)),
          ),
        ],
      ),
    );
  }

  void _showDataUsage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('데이터 사용량', style: TextStyle(color: AppTheme.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이번 달 데이터 사용량:', style: TextStyle(color: AppTheme.white)),
            SizedBox(height: 8),
            Text('• 이미지: 45.2 MB', style: TextStyle(color: AppTheme.grey)),
            Text('• 비디오: 128.7 MB', style: TextStyle(color: AppTheme.grey)),
            Text('• 오디오: 23.1 MB', style: TextStyle(color: AppTheme.grey)),
            Text('• 총합: 197.0 MB', style: TextStyle(color: AppTheme.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인', style: TextStyle(color: AppTheme.accentPink)),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('도움말', style: TextStyle(color: AppTheme.white)),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('JamJam 사용법:', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• 홈: 다른 음악인들의 Jam 세션을 확인하세요', style: TextStyle(color: AppTheme.grey)),
              Text('• 검색: 새로운 음악인들을 찾아보세요', style: TextStyle(color: AppTheme.grey)),
              Text('• Jam: 새로운 Jam 세션을 만들어보세요', style: TextStyle(color: AppTheme.grey)),
              Text('• 채팅: 다른 음악인들과 대화해보세요', style: TextStyle(color: AppTheme.grey)),
              Text('• 프로필: 내 정보를 관리하세요', style: TextStyle(color: AppTheme.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인', style: TextStyle(color: AppTheme.accentPink)),
          ),
        ],
      ),
    );
  }

  void _showContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('문의하기', style: TextStyle(color: AppTheme.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('개발팀에 문의하시려면:', style: TextStyle(color: AppTheme.white)),
            SizedBox(height: 8),
            Text('이메일: support@jamjam.com', style: TextStyle(color: AppTheme.grey)),
            Text('전화: 02-1234-5678', style: TextStyle(color: AppTheme.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인', style: TextStyle(color: AppTheme.accentPink)),
          ),
        ],
      ),
    );
  }

  void _showBugReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('버그 신고', style: TextStyle(color: AppTheme.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('발견한 버그를 신고해주세요:', style: TextStyle(color: AppTheme.white)),
            SizedBox(height: 8),
            Text('이메일: bugs@jamjam.com', style: TextStyle(color: AppTheme.grey)),
            Text('버그 신고 시 앱 버전과 기기 정보를 함께 보내주세요.', style: TextStyle(color: AppTheme.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인', style: TextStyle(color: AppTheme.accentPink)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('개인정보 처리방침', style: TextStyle(color: AppTheme.white)),
        content: const SingleChildScrollView(
          child: Text(
            'JamJam은 사용자의 개인정보를 중요하게 생각합니다.\n\n'
            '수집하는 정보:\n'
            '• 계정 정보 (이메일, 닉네임)\n'
            '• 프로필 정보 (이름, 소개, 악기)\n'
            '• 업로드한 미디어 콘텐츠\n\n'
            '정보 사용 목적:\n'
            '• 서비스 제공 및 개선\n'
            '• 사용자 간 소통\n'
            '• 개인화된 콘텐츠 제공\n\n'
            '정보 보호:\n'
            '• 암호화된 저장 및 전송\n'
            '• 접근 권한 제한\n'
            '• 정기적인 보안 점검',
            style: TextStyle(color: AppTheme.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인', style: TextStyle(color: AppTheme.accentPink)),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('이용약관', style: TextStyle(color: AppTheme.white)),
        content: const SingleChildScrollView(
          child: Text(
            'JamJam 서비스 이용약관\n\n'
            '제1조 (목적)\n'
            '이 약관은 JamJam이 제공하는 서비스의 이용조건 및 절차를 규정합니다.\n\n'
            '제2조 (서비스 내용)\n'
            'JamJam은 음악인들을 위한 소셜 플랫폼 서비스를 제공합니다.\n\n'
            '제3조 (이용자의 의무)\n'
            '이용자는 관련 법령을 준수하고 타인의 권리를 침해하지 않아야 합니다.\n\n'
            '제4조 (서비스 중단)\n'
            '서비스 개선 등을 위해 서비스를 일시 중단할 수 있습니다.',
            style: TextStyle(color: AppTheme.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인', style: TextStyle(color: AppTheme.accentPink)),
          ),
        ],
      ),
    );
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('앱 정보', style: TextStyle(color: AppTheme.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('JamJam', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('버전: 1.0.0', style: TextStyle(color: AppTheme.grey)),
            Text('빌드: 20241201', style: TextStyle(color: AppTheme.grey)),
            Text('개발자: JamJam Team', style: TextStyle(color: AppTheme.grey)),
            SizedBox(height: 8),
            Text('© 2024 JamJam. All rights reserved.', style: TextStyle(color: AppTheme.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인', style: TextStyle(color: AppTheme.accentPink)),
          ),
        ],
      ),
    );
  }
} 