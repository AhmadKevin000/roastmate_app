import 'package:flutter/material.dart';
import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_text.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_radius.dart';
import '../../../domain/inspection_result.dart';
import 'alternative_method_tile.dart';

class BrewRecommendationCard extends StatelessWidget {
  final InspectionResult result;

  const BrewRecommendationCard({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (result.recommendation == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: RoastmateSpacing.lg),
        padding: const EdgeInsets.all(RoastmateSpacing.lg),
        decoration: BoxDecoration(
          color: RoastmateColors.surface,
          borderRadius: BorderRadius.circular(RoastmateRadius.large),
          border: Border.all(color: RoastmateColors.borderDefault),
        ),
        child: Text(
          "Biji masih Green — perlu roasting, tanpa parameter seduh",
          style: RoastmateText.bodyLg.copyWith(color: RoastmateColors.textPrimary),
        ),
      );
    }

    final rec = result.recommendation!;

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
            children: [
              const Icon(Icons.coffee_maker_outlined, size: 16, color: RoastmateColors.textSecondary),
              const SizedBox(width: RoastmateSpacing.sm),
              Text(
                "REKOMENDASI SEDUH TERKALIBRASI",
                style: RoastmateText.labelSm.copyWith(color: RoastmateColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.md),
          Text(
            rec.methodTitle,
            style: RoastmateText.titleLg.copyWith(color: RoastmateColors.textPrimary),
          ),
          const SizedBox(height: RoastmateSpacing.sm),
          Text(
            rec.reasonText,
            style: RoastmateText.bodyMd.copyWith(color: RoastmateColors.textSecondary),
          ),
          const SizedBox(height: RoastmateSpacing.lg),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            mainAxisSpacing: RoastmateSpacing.md,
            crossAxisSpacing: RoastmateSpacing.md,
            children: [
              _buildMetricItem(Icons.scale_outlined, "Rasio Seduh", rec.ratio, rec.ratioSub),
              _buildMetricItem(Icons.thermostat_outlined, "Suhu Air", rec.tempC, rec.tempCSub),
              _buildMetricItem(Icons.blur_circular_outlined, "Tingkat Gilingan", rec.grind, rec.grindSub),
              _buildMetricItem(Icons.timer_outlined, "Target Waktu", rec.targetTime, rec.targetTimeSub),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.lg),
          const Divider(color: RoastmateColors.borderDefault),
          const SizedBox(height: RoastmateSpacing.lg),
          Row(
            children: [
              const Icon(Icons.filter_alt_outlined, size: 16, color: RoastmateColors.textSecondary),
              const SizedBox(width: RoastmateSpacing.sm),
              Text(
                "OPSI METODE ALTERNATIF",
                style: RoastmateText.labelSm.copyWith(color: RoastmateColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.md),
          ...result.alternatives.map((alt) => Padding(
                padding: const EdgeInsets.only(bottom: RoastmateSpacing.sm),
                child: AlternativeMethodTile(method: alt),
              )),
          const SizedBox(height: RoastmateSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Detail Resep akan tersedia di versi berikutnya")),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 16, color: RoastmateColors.primary),
              label: Text("Lihat Detail Resep", style: RoastmateText.labelLg.copyWith(color: RoastmateColors.primary)),
              style: ElevatedButton.styleFrom(
                backgroundColor: RoastmateColors.espressoSoft,
                foregroundColor: RoastmateColors.primary,
                elevation: 0,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RoastmateRadius.small)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(RoastmateSpacing.sm),
      decoration: BoxDecoration(
        color: RoastmateColors.surfaceContainer,
        borderRadius: BorderRadius.circular(RoastmateRadius.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: RoastmateColors.textSecondary),
              const SizedBox(width: 4),
              Text(label, style: RoastmateText.labelSm.copyWith(color: RoastmateColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: RoastmateText.titleMd.copyWith(color: RoastmateColors.textPrimary)),
          Text(sub, style: RoastmateText.bodySm.copyWith(color: RoastmateColors.textSecondary)),
        ],
      ),
    );
  }
}
