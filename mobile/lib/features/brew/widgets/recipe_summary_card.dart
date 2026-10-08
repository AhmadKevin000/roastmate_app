import 'package:flutter/material.dart';

import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_radius.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_text.dart';
import '../../../domain/brew_recipe.dart';
import 'brew_metric_tile.dart';

/// Hero ringkasan resep pada Detail Resep.
class RecipeSummaryCard extends StatelessWidget {
  final BrewMethod method;
  final BrewRecipe recipe;

  const RecipeSummaryCard({
    super.key,
    required this.method,
    required this.recipe,
  });

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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: RoastmateColors.espressoSoft,
                  borderRadius: BorderRadius.circular(RoastmateRadius.medium),
                ),
                child: const Icon(
                  Icons.coffee_maker_outlined,
                  color: RoastmateColors.primary,
                ),
              ),
              const SizedBox(width: RoastmateSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.methodName,
                      style: RoastmateText.titleMd.copyWith(
                        color: RoastmateColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recipe.flavorProfile,
                      style: RoastmateText.bodySm.copyWith(
                        color: RoastmateColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: RoastmateSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: RoastmateColors.espressoSoft,
                  borderRadius: BorderRadius.circular(RoastmateRadius.full),
                ),
                child: Text(
                  'Rasio ${recipe.ratioLabel}',
                  style: RoastmateText.labelSm.copyWith(
                    color: RoastmateColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.lg),
          Row(
            children: [
              Expanded(
                child: BrewMetricTile(
                  stacked: true,
                  label: 'Berat',
                  value: recipe.doseLabel,
                ),
              ),
              const SizedBox(width: RoastmateSpacing.md),
              Expanded(
                child: BrewMetricTile(
                  stacked: true,
                  label: 'Total Air',
                  value: recipe.waterLabel,
                ),
              ),
              const SizedBox(width: RoastmateSpacing.md),
              Expanded(
                child: BrewMetricTile(
                  stacked: true,
                  label: 'Suhu Air',
                  value: recipe.tempLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.md),
          Row(
            children: [
              Expanded(
                child: BrewMetricTile(
                  stacked: true,
                  label: 'Gilingan',
                  value: recipe.grindLabel,
                ),
              ),
              const SizedBox(width: RoastmateSpacing.md),
              Expanded(
                child: BrewMetricTile(
                  stacked: true,
                  label: 'Total Waktu',
                  value: recipe.timeLabel,
                ),
              ),
              const SizedBox(width: RoastmateSpacing.md),
              Expanded(
                child: BrewMetricTile(
                  stacked: true,
                  label: 'Metode',
                  value: recipe.pourLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
