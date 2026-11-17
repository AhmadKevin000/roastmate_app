import 'package:flutter/material.dart';
import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../../../shared/models/analysis_result.dart';
import 'defect_row.dart';

class CompositionBreakdownCard extends StatelessWidget {
  final InspectionResult result;

  const CompositionBreakdownCard({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: RoastmateSpacing.lg),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Rincian Komposisi Biji",
                style: RoastmateText.titleMd.copyWith(color: RoastmateColors.textPrimary),
              ),
              Text(
                "${result.visibleBeans} Total Unit",
                style: RoastmateText.bodySm.copyWith(color: RoastmateColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.md),
          _buildRow(DefectClass.normal, "Biji Normal", "Normal", Icons.check_circle_outline),
          _buildRow(DefectClass.quaker, "Biji Belang / Pucat", "Quaker", Icons.brightness_high_outlined),
          _buildRow(DefectClass.broken, "Biji Patah / Rusak", "Broken", Icons.heart_broken_outlined),
          _buildRow(DefectClass.severe, "Cacat Parah", "Severe", Icons.warning_amber_outlined),
        ],
      ),
    );
  }

  Widget _buildRow(DefectClass defectClass, String label, String subLabel, IconData icon) {
    final count = result.defectCounts[defectClass] ?? 0;
    final percentage = result.percentageForClass(defectClass);
    return DefectRow(
      defectClass: defectClass,
      label: label,
      subLabel: subLabel,
      icon: icon,
      count: count,
      percentage: percentage,
    );
  }
}
