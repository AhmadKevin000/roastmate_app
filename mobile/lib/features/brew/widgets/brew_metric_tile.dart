import 'package:flutter/material.dart';

import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_radius.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_text.dart';

/// Tile metrik seduh.
///
/// `stacked: true` → label di atas, nilai di bawah (grid hero Detail Resep).
/// `stacked: false` → ikon + `label: nilai` sebaris (grid katalog).
class BrewMetricTile extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final bool stacked;

  const BrewMetricTile({
    super.key,
    this.icon,
    required this.label,
    required this.value,
    this.stacked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: stacked
          ? const EdgeInsets.all(RoastmateSpacing.md)
          : const EdgeInsets.symmetric(
              horizontal: RoastmateSpacing.sm,
              vertical: 10,
            ),
      decoration: BoxDecoration(
        color: RoastmateColors.surfaceContainer,
        borderRadius: BorderRadius.circular(RoastmateRadius.small),
      ),
      child: stacked ? _buildStacked() : _buildInline(),
    );
  }

  Widget _buildStacked() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: RoastmateText.bodySm.copyWith(
            color: RoastmateColors.textSecondary,
          ),
        ),
        const SizedBox(height: RoastmateSpacing.xs),
        Text(
          value,
          style: RoastmateText.titleMd.copyWith(
            color: RoastmateColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInline() {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: RoastmateColors.textSecondary),
          const SizedBox(width: 6),
        ],
        Text(
          '$label: ',
          style: RoastmateText.bodySm.copyWith(
            color: RoastmateColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: RoastmateText.labelMd.copyWith(
              color: RoastmateColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
