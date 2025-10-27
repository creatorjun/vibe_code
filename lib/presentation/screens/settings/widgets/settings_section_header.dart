// lib/presentation/screens/settings/widgets/settings_section_header.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/ui_constants.dart';

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(UIConstants.spacingXs),
          decoration: BoxDecoration(
            color: color.withAlpha(UIConstants.alpha20),
            borderRadius: BorderRadius.circular(UIConstants.radiusSm),
          ),
          child: Icon(
            icon,
            size: UIConstants.iconMd,
            color: color,
          ),
        ),
        const SizedBox(width: UIConstants.spacingSm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
