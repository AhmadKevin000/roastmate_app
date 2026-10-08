import 'package:flutter/material.dart';

import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_radius.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_text.dart';

/// Kartu "Tip Seduh Artisan" pada Katalog Seduh.
class BrewingTipCard extends StatelessWidget {
  final String title;
  final String message;

  const BrewingTipCard({
    super.key,
    this.title = 'Tip Seduh Artisan',
    this.message =
        'Suhu air 90–94°C ideal untuk biji Specialty agar tidak mengekstraksi kepahitan berlebih dari tanin yang tak diinginkan.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RoastmateSpacing.lg),
      decoration: BoxDecoration(
        color: RoastmateColors.terracottaSoft,
        borderRadius: BorderRadius.circular(RoastmateRadius.medium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: RoastmateColors.secondary,
            size: 22,
          ),
          const SizedBox(width: RoastmateSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: RoastmateText.titleSm.copyWith(
                    color: RoastmateColors.textPrimary,
                  ),
                ),
                const SizedBox(height: RoastmateSpacing.xs),
                Text(
                  message,
                  style: RoastmateText.bodyMd.copyWith(
                    color: RoastmateColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
