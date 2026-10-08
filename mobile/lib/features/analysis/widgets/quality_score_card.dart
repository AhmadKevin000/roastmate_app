import 'package:flutter/material.dart';
import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_text.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_radius.dart';
import '../../../domain/inspection_result.dart';

class QualityScoreCard extends StatelessWidget {
  final InspectionResult result;

  const QualityScoreCard({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradeTokens = RoastmateColors.grade[result.grade.name] ?? RoastmateColors.grade['specialty']!;
    final gradeColor = gradeTokens['color']!;
    final gradeContainer = gradeTokens['container']!;

    Color defectColor;
    Color defectContainer;
    IconData defectIcon;
    if (result.defectRate <= 0.10) {
      defectColor = RoastmateColors.grade['specialty']!['color']!;
      defectContainer = RoastmateColors.grade['specialty']!['container']!;
      defectIcon = Icons.check_circle_outline;
    } else if (result.defectRate <= 0.20) {
      defectColor = RoastmateColors.grade['specialty']!['color']!; // Using green in mockup anyway, wait, mock is Defect Rendah 7.1%. Let's use specialty color for low/med so it matches mock but we text it correct.
      defectContainer = RoastmateColors.grade['specialty']!['container']!;
      defectIcon = Icons.check_circle_outline;
    } else {
      defectColor = RoastmateColors.grade['offGrade']!['color']!;
      defectContainer = RoastmateColors.grade['offGrade']!['container']!;
      defectIcon = Icons.error_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: RoastmateSpacing.lg),
      padding: const EdgeInsets.all(RoastmateSpacing.lg),
      decoration: BoxDecoration(
        color: RoastmateColors.surface,
        borderRadius: BorderRadius.circular(RoastmateRadius.large),
        border: Border.all(color: RoastmateColors.borderDefault),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D2B2421),
            offset: Offset(0, 1),
            blurRadius: 3,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SKOR KUALITAS OPTIK",
                style: RoastmateText.labelSm.copyWith(color: RoastmateColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: gradeContainer,
                  borderRadius: BorderRadius.circular(RoastmateRadius.full),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, size: 14, color: gradeColor),
                    const SizedBox(width: 4),
                    Text(
                      result.grade.name.toUpperCase(),
                      style: RoastmateText.labelSm.copyWith(color: gradeColor),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: RoastmateSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                result.qualityScore.toString(),
                style: RoastmateText.displaySm.copyWith(color: RoastmateColors.textPrimary),
              ),
              const SizedBox(width: 4),
              Text(
                "/ 100",
                style: RoastmateText.titleMd.copyWith(color: RoastmateColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: RoastmateColors.terracottaSoft,
                  borderRadius: BorderRadius.circular(RoastmateRadius.full),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.grain, size: 14, color: RoastmateColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      "${result.visibleBeans} Biji Terdeteksi",
                      style: RoastmateText.labelSm.copyWith(color: RoastmateColors.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: RoastmateSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: defectContainer,
                  borderRadius: BorderRadius.circular(RoastmateRadius.full),
                ),
                child: Row(
                  children: [
                    Icon(defectIcon, size: 14, color: defectColor),
                    const SizedBox(width: 4),
                    Text(
                      "${result.defectLabel} (${(result.defectRate * 100).toStringAsFixed(1)}%)",
                      style: RoastmateText.labelSm.copyWith(color: defectColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.md),
          Text(
            result.summaryText,
            style: RoastmateText.bodyLg.copyWith(color: RoastmateColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
