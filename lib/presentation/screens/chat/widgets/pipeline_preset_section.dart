// lib/presentation/screens/chat/widgets/pipeline_preset_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/ui_constants.dart';
import 'pipeline_depth_selector.dart';
import 'preset_selector.dart';

class PipelinePresetSection extends ConsumerWidget {
  const PipelinePresetSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacingMd,
        vertical: UIConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withAlpha(UIConstants.alpha30),
            width: 1,
          ),
        ),
      ),
      child: const Row(
        children: [
          IntrinsicWidth(
            child: PipelineDepthSelector(),
          ),
          SizedBox(width: UIConstants.spacingMd),
          Expanded(
            child: PresetSelector(),
          ),
        ],
      ),
    );
  }
}
