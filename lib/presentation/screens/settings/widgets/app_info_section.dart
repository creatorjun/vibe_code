// lib/presentation/screens/settings/widgets/app_info_section.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/ui_constants.dart';
import 'settings_section_header.dart';
import 'settings_card.dart';

class AppInfoSection extends StatelessWidget {
  const AppInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(
          icon: Icons.info_outline_rounded,
          title: '앱 정보',
          color: colorScheme.primary,
        ),
        const SizedBox(height: UIConstants.spacingMd),
        SettingsCard(
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.verified_rounded,
                title: '버전',
                subtitle: AppConstants.appVersion,
                color: colorScheme.primary,
              ),
              Divider(
                height: 1,
                indent: UIConstants.spacingMd,
                endIndent: UIConstants.spacingMd,
              ),
              _InfoTile(
                icon: Icons.code_rounded,
                title: 'GitHub',
                subtitle: 'creator-jun/vibe_code',
                color: colorScheme.secondary,
                onTap: () {
                  // GitHub 링크 열기 (선택사항)
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 정보 타일 위젯
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(UIConstants.spacingSm),
        decoration: BoxDecoration(
          color: color.withAlpha(UIConstants.alpha20),
          borderRadius: BorderRadius.circular(UIConstants.radiusSm),
        ),
        child: Icon(
          icon,
          color: color,
          size: UIConstants.iconMd,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: onTap != null
          ? Icon(
        Icons.open_in_new,
        size: UIConstants.iconSm,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacingMd,
        vertical: UIConstants.spacingSm,
      ),
    );
  }
}
