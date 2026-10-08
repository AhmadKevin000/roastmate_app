import 'package:flutter/material.dart';

import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_radius.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_text.dart';
import '../../../domain/brew_recipe.dart';

/// Bagian "Persiapan & Alat Seduh" pada Detail Resep.
///
/// Berisi langkah ber-`phase` `prep` (D-18).
class PreparationList extends StatelessWidget {
  final List<BrewStep> steps;

  const PreparationList({super.key, required this.steps});

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
                Icons.construction_outlined,
                size: 18,
                color: RoastmateColors.textSecondary,
              ),
              const SizedBox(width: RoastmateSpacing.sm),
              Expanded(
                child: Text(
                  'Persiapan & Alat Seduh',
                  style: RoastmateText.titleMd.copyWith(
                    color: RoastmateColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${steps.length} Alat Utama',
                style: RoastmateText.bodySm.copyWith(
                  color: RoastmateColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.md),
          for (final step in steps) _PreparationItem(step: step),
        ],
      ),
    );
  }
}

class _PreparationItem extends StatelessWidget {
  final BrewStep step;

  const _PreparationItem({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: RoastmateSpacing.sm),
      padding: const EdgeInsets.all(RoastmateSpacing.md),
      decoration: BoxDecoration(
        color: RoastmateColors.surface,
        borderRadius: BorderRadius.circular(RoastmateRadius.small),
        border: Border.all(color: RoastmateColors.borderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: RoastmateText.titleSm.copyWith(
                    color: RoastmateColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.description,
                  style: RoastmateText.bodySm.copyWith(
                    color: RoastmateColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: RoastmateSpacing.sm),
          const Icon(
            Icons.check_circle_outline,
            size: 20,
            color: RoastmateColors.tertiary,
          ),
        ],
      ),
    );
  }
}
