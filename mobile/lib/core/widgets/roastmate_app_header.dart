import 'package:flutter/material.dart';

import '../theme/roastmate_colors.dart';
import '../theme/roastmate_radius.dart';
import '../theme/roastmate_spacing.dart';
import '../theme/roastmate_text.dart';

/// Header brand yang konsisten untuk layar bertab (Beranda, Analisis, Seduh).
///
/// Menampilkan logo aplikasi, nama "Roastmate", sublabel tab aktif, dan ikon
/// pengaturan. Tidak memakai avatar.
class RoastmateAppHeader extends StatelessWidget {
  /// Sublabel tab aktif (mis. "Beranda", "Analisis", "Seduh").
  final String subtitle;

  final VoidCallback? onSettings;

  const RoastmateAppHeader({
    super.key,
    required this.subtitle,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(RoastmateRadius.small),
              ),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
            ),
            const SizedBox(width: RoastmateSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Roastmate',
                  style: RoastmateText.titleMd.copyWith(
                    color: RoastmateColors.primary,
                  ),
                ),
                Text(
                  subtitle,
                  style: RoastmateText.bodySm.copyWith(
                    color: RoastmateColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: onSettings,
          icon: const Icon(
            Icons.settings_outlined,
            color: RoastmateColors.primary,
          ),
        ),
      ],
    );
  }
}
