import 'package:flutter/material.dart';
import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_text.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_radius.dart';

/// Header atas tab Analisis: logo, nama app, ikon pengaturan, dan avatar.
class HistoryAppHeader extends StatelessWidget {
  final VoidCallback? onSettings;
  final VoidCallback? onProfile;

  const HistoryAppHeader({Key? key, this.onSettings, this.onProfile}) : super(key: key);

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
                  style: RoastmateText.titleSm.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: RoastmateColors.primary,
                  ),
                ),
                Text(
                  'Analisis',
                  style: RoastmateText.bodyMd.copyWith(
                    color: RoastmateColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: onSettings,
              icon: const Icon(Icons.settings_outlined, color: RoastmateColors.primary),
            ),
            const SizedBox(width: RoastmateSpacing.sm),
            GestureDetector(
              onTap: onProfile,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: RoastmateColors.primary,
                child: Icon(Icons.person, color: RoastmateColors.surface, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
