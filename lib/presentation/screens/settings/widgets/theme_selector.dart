import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/providers/theme_provider.dart';
import '../../../../core/constants/ui_constants.dart';

class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더 (현대적 디자인)
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.spacingXs),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(UIConstants.radiusSm),
              ),
              child: Icon(
                Icons.palette_outlined,
                size: UIConstants.iconMd,
              ),
            ),
            const SizedBox(width: UIConstants.spacingSm),
            Text(
              '테마',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: UIConstants.spacingMd),

        // 카드로 감싸기
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusLg),
            side: BorderSide(
              color: colorScheme.outlineVariant.withAlpha(UIConstants.alpha60),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(UIConstants.spacingMd),
            // ✅ SizedBox로 감싸서 전체 너비로 확장
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('라이트'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('다크'),
                    icon: Icon(Icons.dark_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('시스템'),
                    icon: Icon(Icons.settings_suggest),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (Set<ThemeMode> selected) {
                  ref.read(appThemeModeProvider.notifier).setThemeMode(selected.first);
                },
                // ✅ 버튼들이 균등하게 확장되도록 설정
                style: ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
