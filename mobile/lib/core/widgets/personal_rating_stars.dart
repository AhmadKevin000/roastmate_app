import 'package:flutter/material.dart';

import '../theme/roastmate_colors.dart';
import '../theme/roastmate_spacing.dart';
import '../theme/roastmate_text.dart';

/// Baris bintang ringkas untuk penilaian pribadi user (bintang 1–5).
///
/// Dipakai kartu ringkasan di Beranda dan tab Analisis agar penilaian yang
/// diisi di Detail Inspeksi terlihat tanpa membuka detail. `stars` null/0
/// berarti belum dinilai: bintang outline + label redup.
class PersonalRatingStars extends StatelessWidget {
  const PersonalRatingStars({
    super.key,
    required this.stars,
    this.size = 14,
    this.showLabel = true,
  });

  /// Bintang tersimpan (`analyses.personal_rating`); null = belum dinilai.
  final int? stars;

  /// Ukuran ikon bintang.
  final double size;

  /// Tampilkan label `n/5` / `Belum dinilai` di kanan bintang.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final filled = (stars ?? 0).clamp(0, 5);
    final hasRating = filled > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: i <= filled
                ? RoastmateColors.secondary
                : RoastmateColors.iconMuted,
          ),
        if (showLabel) ...[
          const SizedBox(width: RoastmateSpacing.xs),
          Text(
            hasRating ? '$filled/5' : 'Belum dinilai',
            style: RoastmateText.labelSm.copyWith(
              color: hasRating
                  ? RoastmateColors.secondary
                  : RoastmateColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
