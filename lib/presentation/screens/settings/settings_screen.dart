import 'package:flutter/material.dart';
import '../../../core/constants/ui_constants.dart';
import 'widgets/api_settings.dart';
import 'widgets/model_selector.dart';
import 'widgets/theme_selector.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(UIConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ApiSettings(),
            const SizedBox(height: UIConstants.spacingXl),
            const ModelSelector(),
            const SizedBox(height: UIConstants.spacingXl),
            const ThemeSelector(),
            const SizedBox(height: UIConstants.spacingXl),

            // 앱 정보
            Text(
              '앱 정보',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: UIConstants.spacingMd),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('버전'),
              subtitle: const Text('2.0.0'),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('GitHub'),
              subtitle: const Text('creatorjun/vibe_code'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
