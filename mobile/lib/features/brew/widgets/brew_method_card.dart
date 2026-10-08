import 'package:flutter/material.dart';

import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_radius.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_text.dart';
import '../../../domain/brew_recipe.dart';
import 'brew_metric_tile.dart';

/// Kartu metode pada Katalog Seduh (layar "Resep Seduh").
class BrewMethodCard extends StatelessWidget {
  final BrewMethod method;
  final BrewRecipe? recipe;
  final VoidCallback onStartSetup;

  const BrewMethodCard({
    super.key,
    required this.method,
    required this.recipe,
    required this.onStartSetup,
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
                      style: RoastmateText.titleLg.copyWith(
                        color: RoastmateColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method.subtitle,
                      style: RoastmateText.bodySm.copyWith(
                        color: RoastmateColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(RoastmateSpacing.md),
            decoration: BoxDecoration(
              color: RoastmateColors.surfaceContainer,
              borderRadius: BorderRadius.circular(RoastmateRadius.small),
            ),
            child: Text(
              '“${method.description}”',
              style: RoastmateText.bodyMd.copyWith(
                color: RoastmateColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: RoastmateSpacing.md),
          Row(
            children: [
              Expanded(
                child: BrewMetricTile(
                  icon: Icons.scale_outlined,
                  label: 'Rasio',
                  value: recipe?.ratioLabel ?? '—',
                ),
              ),
              const SizedBox(width: RoastmateSpacing.md),
              Expanded(
                child: BrewMetricTile(
                  icon: Icons.timer_outlined,
                  label: 'Waktu',
                  value: recipe?.timeLabel ?? '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.md),
          Row(
            children: [
              Expanded(
                child: BrewMetricTile(
                  icon: Icons.grain,
                  label: 'Grind',
                  value: recipe?.grindLabel ?? '—',
                ),
              ),
              const SizedBox(width: RoastmateSpacing.md),
              Expanded(
                child: BrewMetricTile(
                  icon: Icons.thermostat_outlined,
                  label: 'Suhu',
                  value: recipe?.tempLabel ?? '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStartSetup,
              icon: const Icon(Icons.tune, size: 18),
              label: Text('Mulai Setup', style: RoastmateText.labelLg),
              style: ElevatedButton.styleFrom(
                backgroundColor: RoastmateColors.terracottaSoft,
                foregroundColor: RoastmateColors.primary,
                elevation: 0,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RoastmateRadius.small),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
