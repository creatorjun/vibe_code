// lib/presentation/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/ui_constants.dart';
import 'widgets/api_settings.dart';
import 'widgets/model_pipeline_settings.dart';
import 'widgets/preset_management_section.dart';
import 'widgets/theme_selector.dart';
import 'widgets/data_management_section.dart';
import 'widgets/app_info_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 3,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(UIConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API 설정
            ApiSettings(),
            SizedBox(height: UIConstants.spacingLg),

            // 모델 파이프라인 설정
            ModelPipelineSettings(),
            SizedBox(height: UIConstants.spacingLg),

            // ✅ 프리셋 관리 섹션 추가
            PresetManagementSection(),
            SizedBox(height: UIConstants.spacingLg),

            // 테마 선택
            ThemeSelector(),
            SizedBox(height: UIConstants.spacingLg),

            // 데이터 관리
            DataManagementSection(),
            SizedBox(height: UIConstants.spacingLg),

            // 앱 정보
            AppInfoSection(),
            SizedBox(height: UIConstants.spacingXl),
          ],
        ),
      ),
    );
  }
}
