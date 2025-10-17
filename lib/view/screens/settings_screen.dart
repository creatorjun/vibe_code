import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/constants/ui_constants.dart';
import '../../common/utils/ui_helpers.dart';

/// 설정 화면
///
/// API 키 설정, 테마 변경, 앱 정보 등을 표시합니다.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;
  ThemeMode _selectedThemeMode = ThemeMode.system;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isWideScreen = width >= 600;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isWideScreen ? UIConstants.spacing32 : UIConstants.spacing16,
          vertical: UIConstants.spacing16,
        ),
        children: [
          _buildApiKeySection(isDark),
          const SizedBox(height: UIConstants.spacing32),
          _buildThemeSection(isDark),
          const SizedBox(height: UIConstants.spacing32),
          _buildAboutSection(isDark),
        ],
      ),
    );
  }

  /// AppBar 빌더
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('설정'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  /// API 키 섹션 빌더
  Widget _buildApiKeySection(bool isDark) {
    return _buildSection(
      isDark: isDark,
      title: 'API 키 설정',
      icon: Icons.key,
      children: [
        const SizedBox(height: UIConstants.spacing16),
        TextField(
          controller: _apiKeyController,
          obscureText: _obscureApiKey,
          decoration: InputDecoration(
            labelText: 'OpenAI API Key',
            hintText: 'sk-...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                size: UIConstants.iconMedium,
              ),
              onPressed: () {
                setState(() {
                  _obscureApiKey = !_obscureApiKey;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: UIConstants.spacing12),
        _buildInfoBox(
          isDark: isDark,
          text: 'API 키는 로컬에 안전하게 저장되며, 외부로 전송되지 않습니다.',
        ),
        const SizedBox(height: UIConstants.spacing16),
        _buildActionButton(
          isDark: isDark,
          label: '저장',
          icon: Icons.save,
          onPressed: () {
            // TODO: API 키 저장 로직 구현
            _showSnackBar('API 키가 저장되었습니다');
          },
        ),
      ],
    );
  }

  /// 테마 섹션 빌더
  Widget _buildThemeSection(bool isDark) {
    return _buildSection(
      isDark: isDark,
      title: '테마 설정',
      icon: Icons.palette,
      children: [
        const SizedBox(height: UIConstants.spacing16),
        _buildThemeOption(
          isDark: isDark,
          title: '라이트 모드',
          value: ThemeMode.light,
          icon: Icons.light_mode,
        ),
        const SizedBox(height: UIConstants.spacing8),
        _buildThemeOption(
          isDark: isDark,
          title: '다크 모드',
          value: ThemeMode.dark,
          icon: Icons.dark_mode,
        ),
        const SizedBox(height: UIConstants.spacing8),
        _buildThemeOption(
          isDark: isDark,
          title: '시스템 설정 따르기',
          value: ThemeMode.system,
          icon: Icons.settings_system_daydream,
        ),
      ],
    );
  }

  /// 앱 정보 섹션 빌더
  Widget _buildAboutSection(bool isDark) {
    return _buildSection(
      isDark: isDark,
      title: '앱 정보',
      icon: Icons.info,
      children: [
        const SizedBox(height: UIConstants.spacing16),
        _buildInfoRow('버전', '1.0.0', isDark),
        const SizedBox(height: UIConstants.spacing12),
        _buildInfoRow('개발자', 'Vibe Code Team', isDark),
        const SizedBox(height: UIConstants.spacing12),
        _buildInfoRow('라이선스', 'MIT License', isDark),
        const SizedBox(height: UIConstants.spacing16),
        _buildActionButton(
          isDark: isDark,
          label: 'GitHub에서 보기',
          icon: Icons.code,
          onPressed: () {
            // TODO: GitHub 링크 열기
            _showSnackBar('GitHub 페이지로 이동합니다');
          },
        ),
      ],
    );
  }

  /// 섹션 컨테이너 빌더
  Widget _buildSection({
    required bool isDark,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return UIHelpers.buildFloatingGlass(
      isDark: isDark,
      alpha: UIConstants.glassAlphaMedium,
      borderRadius: UIConstants.radiusXLarge,
      padding: const EdgeInsets.all(UIConstants.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: UIConstants.iconLarge,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              const SizedBox(width: UIConstants.spacing12),
              Text(
                title,
                style: UIHelpers.getTextStyle(
                  isDark: isDark,
                  fontSize: UIConstants.fontLarge,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  /// 테마 옵션 빌더
  Widget _buildThemeOption({
    required bool isDark,
    required String title,
    required ThemeMode value,
    required IconData icon,
  }) {
    return UIHelpers.buildFloatingButton(
      isDark: isDark,
      onTap: () {
        setState(() {
          _selectedThemeMode = value;
        });
        // TODO: 테마 변경 provider 호출
        _showSnackBar('테마가 변경되었습니다');
      },
      alpha: _selectedThemeMode == value
          ? UIConstants.glassAlphaHigh
          : UIConstants.glassAlphaLow,
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing16,
        vertical: UIConstants.spacing12,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: UIConstants.iconMedium,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          const SizedBox(width: UIConstants.spacing12),
          Text(
            title,
            style: UIHelpers.getTextStyle(
              isDark: isDark,
              fontSize: UIConstants.fontMedium,
            ),
          ),
          const Spacer(),
          if (_selectedThemeMode == value)
            Icon(
              Icons.check_circle,
              size: UIConstants.iconMedium,
              color: isDark ? Colors.greenAccent : Colors.green,
            ),
        ],
      ),
    );
  }

  /// 정보 박스 빌더
  Widget _buildInfoBox({
    required bool isDark,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: UIConstants.iconSmall,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: UIConstants.spacing8),
          Expanded(
            child: Text(
              text,
              style: UIHelpers.getTextStyle(
                isDark: isDark,
                fontSize: UIConstants.fontSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 정보 행 빌더
  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: UIHelpers.getTextStyle(
            isDark: isDark,
            fontSize: UIConstants.fontMedium,
            isSecondary: true,
          ),
        ),
        Text(
          value,
          style: UIHelpers.getTextStyle(
            isDark: isDark,
            fontSize: UIConstants.fontMedium,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 액션 버튼 빌더
  Widget _buildActionButton({
    required bool isDark,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: UIHelpers.buildFloatingButton(
        isDark: isDark,
        onTap: onPressed,
        alpha: UIConstants.glassAlphaMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: UIConstants.spacing16,
          vertical: UIConstants.spacing12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: UIConstants.iconMedium,
              color: isDark ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: UIConstants.spacing8),
            Text(
              label,
              style: UIHelpers.getTextStyle(
                isDark: isDark,
                fontSize: UIConstants.fontMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 스낵바 표시 헬퍼
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
