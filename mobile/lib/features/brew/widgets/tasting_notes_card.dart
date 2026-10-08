import 'package:flutter/material.dart';

import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_radius.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_text.dart';

/// Kartu "Artisan Pro-Tips: Kalibrasi Rasa" pada Detail Resep (FR-07).
class TastingNotesCard extends StatelessWidget {
  final String? intro;

  const TastingNotesCard({super.key, this.intro});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RoastmateSpacing.lg),
      decoration: BoxDecoration(
        color: RoastmateColors.terracottaSoft,
        borderRadius: BorderRadius.circular(RoastmateRadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: RoastmateColors.secondary,
              ),
              const SizedBox(width: RoastmateSpacing.sm),
              Expanded(
                child: Text(
                  'Artisan Pro-Tips: Kalibrasi Rasa',
                  style: RoastmateText.titleMd.copyWith(
                    color: RoastmateColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.md),
          Text(
            intro ??
                'Rasa kopi dipengaruhi oleh laju aliran dan ukuran gilingan:',
            style: RoastmateText.bodyMd.copyWith(
              color: RoastmateColors.textSecondary,
            ),
          ),
          const SizedBox(height: RoastmateSpacing.md),
          const _TastingTip(
            icon: Icons.arrow_upward,
            title: 'Terlalu Pahit / Sepet (Over-extracted):',
            description:
                'Percepat penuangan atau perhalus sedikit gilingan (grind size).',
          ),
          const SizedBox(height: RoastmateSpacing.sm),
          const _TastingTip(
            icon: Icons.arrow_downward,
            title: 'Terlalu Asam Tajam / Encer (Under-extracted):',
            description:
                'Perlambat penuangan atau perhalus gilingan untuk kontak air lebih lama.',
          ),
        ],
      ),
    );
  }
}

class _TastingTip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TastingTip({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: RoastmateColors.primary),
        const SizedBox(width: RoastmateSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: RoastmateText.bodyMd.copyWith(
                color: RoastmateColors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: '$title ',
                  style: RoastmateText.bodyMd.copyWith(
                    color: RoastmateColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
