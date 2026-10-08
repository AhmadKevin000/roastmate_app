import 'package:flutter/material.dart';
import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_text.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_radius.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: RoastmateSpacing.lg),
      padding: const EdgeInsets.all(RoastmateSpacing.md),
      decoration: BoxDecoration(
        color: RoastmateColors.statusInfoContainer,
        borderRadius: BorderRadius.circular(RoastmateRadius.small),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: RoastmateColors.statusInfo),
          const SizedBox(width: RoastmateSpacing.md),
          Expanded(
            child: Text(
              "Roastmate hanya menilai biji yang terlihat pada permukaan foto dan merupakan penilaian indikatif proyek, bukan sertifikasi laboratorium fisik resmi.",
              style: RoastmateText.bodySm.copyWith(color: RoastmateColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
