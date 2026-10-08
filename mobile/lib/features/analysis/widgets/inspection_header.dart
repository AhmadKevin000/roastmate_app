import 'package:flutter/material.dart';
import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_text.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_radius.dart';

class InspectionHeader extends StatelessWidget {
  final String batchLabel;
  final String batchName;
  final String analyzedAgo;

  const InspectionHeader({
    Key? key,
    required this.batchLabel,
    required this.batchName,
    required this.analyzedAgo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RoastmateSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: RoastmateColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(RoastmateRadius.micro),
                      ),
                      child: Text(
                        batchLabel,
                        style: RoastmateText.labelMd.copyWith(color: RoastmateColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: RoastmateSpacing.sm),
                    Expanded(
                      child: Text(
                        batchName,
                        style: RoastmateText.titleSm.copyWith(color: RoastmateColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: RoastmateSpacing.xs),
                Text(
                  analyzedAgo,
                  style: RoastmateText.bodySm.copyWith(color: RoastmateColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: RoastmateSpacing.lg),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Ekspor CSV akan tersedia di versi berikutnya")),
              );
            },
            icon: const Icon(Icons.share, size: 16, color: RoastmateColors.textPrimary),
            label: Text("Ekspor", style: RoastmateText.labelMd.copyWith(color: RoastmateColors.textPrimary)),
            style: OutlinedButton.styleFrom(
              foregroundColor: RoastmateColors.textPrimary,
              side: const BorderSide(color: RoastmateColors.borderDefault),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RoastmateRadius.full),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              minimumSize: const Size(0, 36),
            ),
          )
        ],
      ),
    );
  }
}
