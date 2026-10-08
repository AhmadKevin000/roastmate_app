import 'package:flutter/material.dart';

import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_radius.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_text.dart';
import '../../../domain/brew_recipe.dart';

/// Bagian "Panduan Langkah" pada Detail Resep.
///
/// Panduan **statis**: hanya label target waktu sebagai informasi.
/// Tidak ada timer, countdown, atau kontrol start/stop (D-01).
class BrewingStepList extends StatelessWidget {
  final List<BrewStep> steps;

  const BrewingStepList({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RoastmateSpacing.lg),
      decoration: BoxDecoration(
        color: RoastmateColors.surface,
        borderRadius: BorderRadius.circular(RoastmateRadius.large),
        border: Border.all(color: RoastmateColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.format_list_numbered,
                size: 18,
                color: RoastmateColors.textSecondary,
              ),
              const SizedBox(width: RoastmateSpacing.sm),
              Text(
                'Panduan Langkah',
                style: RoastmateText.titleMd.copyWith(
                  color: RoastmateColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.lg),
          for (var i = 0; i < steps.length; i++)
            _StepItem(
              step: steps[i],
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final BrewStep step;
  final bool isLast;

  const _StepItem({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: RoastmateColors.espressoSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${step.stepNo}',
                    style: RoastmateText.labelMd.copyWith(
                      color: RoastmateColors.primary,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: RoastmateColors.borderDefault,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: RoastmateSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : RoastmateSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          style: RoastmateText.titleSm.copyWith(
                            color: RoastmateColors.textPrimary,
                          ),
                        ),
                      ),
                      if (step.targetTime != null) ...[
                        const SizedBox(width: RoastmateSpacing.sm),
                        _TargetTimeChip(label: step.targetTime!),
                      ],
                    ],
                  ),
                  const SizedBox(height: RoastmateSpacing.xs),
                  Text(
                    step.description,
                    style: RoastmateText.bodyMd.copyWith(
                      color: RoastmateColors.textSecondary,
                    ),
                  ),
                  if (step.callout != null) ...[
                    const SizedBox(height: RoastmateSpacing.sm),
                    _CalloutBox(text: step.callout!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetTimeChip extends StatelessWidget {
  final String label;

  const _TargetTimeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: RoastmateColors.surfaceContainer,
        borderRadius: BorderRadius.circular(RoastmateRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule,
            size: 12,
            color: RoastmateColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: RoastmateText.labelSm.copyWith(
              color: RoastmateColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalloutBox extends StatelessWidget {
  final String text;

  const _CalloutBox({required this.text});

  @override
  Widget build(BuildContext context) {
    final isWeight = text.toLowerCase().contains('ml');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RoastmateSpacing.md,
        vertical: RoastmateSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: RoastmateColors.terracottaSoft,
        borderRadius: BorderRadius.circular(RoastmateRadius.small),
      ),
      child: Row(
        children: [
          Icon(
            isWeight ? Icons.scale_outlined : Icons.autorenew,
            size: 14,
            color: RoastmateColors.secondary,
          ),
          const SizedBox(width: RoastmateSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: RoastmateText.bodySm.copyWith(
                color: RoastmateColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
