import 'package:flutter/material.dart';
import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_text.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_radius.dart';
import '../../../domain/analysis_history_item.dart';

/// Kartu satu analisis pada daftar riwayat.
class HistoryCard extends StatelessWidget {
  final AnalysisHistoryItem item;
  final VoidCallback? onTap;

  const HistoryCard({Key? key, required this.item, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradeTokens =
        RoastmateColors.grade[item.grade.name] ?? RoastmateColors.grade['standard']!;
    final gradeColor = gradeTokens['color']!;
    final gradeContainer = gradeTokens['container']!;

    final defectTotal = item.defectTotal;
    final defectNames = item.defectClasses.map(defectShortLabel).join(', ');
    final hasDefect = defectTotal > 0;
    final defectText = !hasDefect
        ? 'Tidak ada defect'
        : (defectNames.isEmpty ? '$defectTotal defect' : '$defectTotal defect ($defectNames)');

    return Material(
      color: RoastmateColors.surface,
      borderRadius: BorderRadius.circular(RoastmateRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RoastmateRadius.large),
        child: Container(
          padding: const EdgeInsets.all(RoastmateSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RoastmateRadius.large),
            border: Border.all(color: RoastmateColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.batchName,
                      style: RoastmateText.titleMd.copyWith(color: RoastmateColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: RoastmateSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        item.qualityScore.toString(),
                        style: RoastmateText.headlineSm.copyWith(color: RoastmateColors.textPrimary),
                      ),
                      Text(
                        '/100',
                        style: RoastmateText.bodySm.copyWith(color: RoastmateColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: RoastmateSpacing.xs),
              Text(
                item.dateLabel,
                style: RoastmateText.bodySm.copyWith(color: RoastmateColors.textSecondary),
              ),
              const SizedBox(height: RoastmateSpacing.md),
              Row(
                children: [
                  _buildChip(
                    label: item.species,
                    background: RoastmateColors.espressoSoft,
                    foreground: RoastmateColors.secondary,
                  ),
                  const SizedBox(width: RoastmateSpacing.sm),
                  Flexible(
                    child: _buildChip(
                      label: gradeDisplayLabel(item.grade),
                      background: gradeContainer,
                      foreground: gradeColor,
                      icon: Icons.verified,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: RoastmateSpacing.md),
              const Divider(color: RoastmateColors.borderDefault, height: 1),
              const SizedBox(height: RoastmateSpacing.md),
              Row(
                children: [
                  const Icon(Icons.grid_on, size: 14, color: RoastmateColors.iconMuted),
                  const SizedBox(width: RoastmateSpacing.xs),
                  Text(
                    '${item.visibleBeans} biji terlihat',
                    style: RoastmateText.bodySm.copyWith(color: RoastmateColors.textSecondary),
                  ),
                  const Spacer(),
                  Icon(
                    hasDefect ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    size: 14,
                    color: hasDefect ? RoastmateColors.secondary : RoastmateColors.tertiary,
                  ),
                  const SizedBox(width: RoastmateSpacing.xs),
                  Flexible(
                    child: Text(
                      defectText,
                      style: RoastmateText.bodySm.copyWith(color: RoastmateColors.textSecondary),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required Color background,
    required Color foreground,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(RoastmateRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: RoastmateSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              style: RoastmateText.labelSm.copyWith(color: foreground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
