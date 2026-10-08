import 'package:flutter/material.dart';
import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_text.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_radius.dart';
import '../../../domain/inspection_result.dart';

class DefectRow extends StatelessWidget {
  final DefectClass defectClass;
  final String label;
  final String subLabel;
  final IconData icon;
  final int count;
  final double percentage;

  const DefectRow({
    Key? key,
    required this.defectClass,
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.count,
    required this.percentage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = count == 0;
    final colorName = defectClass.name == 'insectDamage' ? 'insect' : (defectClass.name == 'foreignMatter' ? 'foreign' : defectClass.name);
    final color = RoastmateColors.defect[colorName] ?? RoastmateColors.primary;
    final containerColor = color.withOpacity(0.15);

    return Opacity(
      opacity: isEmpty ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: RoastmateSpacing.sm),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: isEmpty ? RoastmateColors.iconMuted : color),
                const SizedBox(width: RoastmateSpacing.sm),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "$label ",
                          style: RoastmateText.bodyMd.copyWith(color: RoastmateColors.textPrimary),
                        ),
                        TextSpan(
                          text: "($subLabel)",
                          style: RoastmateText.bodyMd.copyWith(color: RoastmateColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  "$count biji",
                  style: RoastmateText.titleSm.copyWith(color: RoastmateColors.textPrimary),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 50,
                  child: Text(
                    "(${percentage.toStringAsFixed(1)}%)",
                    style: RoastmateText.bodySm.copyWith(color: RoastmateColors.textSecondary),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: RoastmateSpacing.xs),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: containerColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
              borderRadius: BorderRadius.circular(RoastmateRadius.full),
            ),
          ],
        ),
      ),
    );
  }
}
