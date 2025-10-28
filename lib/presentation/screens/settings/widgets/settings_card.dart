import 'package:flutter/material.dart';
import '../../../../core/constants/ui_constants.dart';

class SettingsCard extends StatelessWidget {
  final Widget child;

  const SettingsCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusLg),
        side: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withAlpha(UIConstants.alpha60),
        ),
      ),
      child: child,
    );
  }
}
