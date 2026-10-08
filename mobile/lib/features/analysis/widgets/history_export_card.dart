import 'package:flutter/material.dart';
import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_text.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_radius.dart';

/// Kartu ajakan ekspor rekap hasil grading ke CSV.
class HistoryExportCard extends StatelessWidget {
  final VoidCallback? onExport;

  const HistoryExportCard({Key? key, this.onExport}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RoastmateSpacing.lg),
      decoration: BoxDecoration(
        color: RoastmateColors.surfaceContainer,
        borderRadius: BorderRadius.circular(RoastmateRadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: RoastmateColors.surface,
                  borderRadius: BorderRadius.circular(RoastmateRadius.small),
                ),
                child: const Icon(Icons.description_outlined, color: RoastmateColors.secondary),
              ),
              const SizedBox(width: RoastmateSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rekap Hasil Grading Batch',
                      style: RoastmateText.titleSm.copyWith(color: RoastmateColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Perlu data lengkap untuk evaluasi lab atau spreadsheet?',
                      style: RoastmateText.bodySm.copyWith(color: RoastmateColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.download, size: 18, color: RoastmateColors.surface),
              label: Text(
                'Ekspor CSV (.csv)',
                style: RoastmateText.labelLg.copyWith(color: RoastmateColors.surface),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: RoastmateColors.primary,
                foregroundColor: RoastmateColors.surface,
                minimumSize: const Size(0, 48),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RoastmateRadius.small),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
