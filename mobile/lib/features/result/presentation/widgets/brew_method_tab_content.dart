import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../../../../shared/models/analysis_result.dart';

/// Isi satu tab pada kartu rekomendasi seduh.
///
/// Tab utama menampilkan parameter seduh lengkap; tab alternatif menampilkan
/// judul + deskripsi yang tersedia. Setiap tab punya CTA ke Detail Resep
/// (`/brewing/:methodId`) bila [methodId] dikenal.
class BrewMethodTabContent extends StatelessWidget {
  final BrewRecommendation? primary;
  final AlternativeMethod? alternative;
  final String? methodId;

  const BrewMethodTabContent({
    super.key,
    this.primary,
    this.alternative,
    this.methodId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (primary != null) ...[
          Text(
            primary!.methodTitle,
            style: RoastmateText.titleLg.copyWith(
              color: RoastmateColors.textPrimary,
            ),
          ),
          const SizedBox(height: RoastmateSpacing.sm),
          Text(
            primary!.reasonText,
            style: RoastmateText.bodyMd.copyWith(
              color: RoastmateColors.textSecondary,
            ),
          ),
          const SizedBox(height: RoastmateSpacing.lg),
          _buildMetrics(primary!),
        ] else if (alternative != null) ...[
          Text(
            alternative!.title,
            style: RoastmateText.titleLg.copyWith(
              color: RoastmateColors.textPrimary,
            ),
          ),
          const SizedBox(height: RoastmateSpacing.sm),
          Text(
            alternative!.description,
            style: RoastmateText.bodyMd.copyWith(
              color: RoastmateColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: RoastmateSpacing.lg),
        _buildCta(context),
      ],
    );
  }

  Widget _buildMetrics(BrewRecommendation rec) {
    // Tinggi mengikuti isi: tiap sel boleh 1 atau 2 baris teks tanpa terpotong.
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildMetricItem(
                  Icons.scale_outlined,
                  "Rasio Seduh",
                  rec.ratio,
                  rec.ratioSub,
                ),
              ),
              const SizedBox(width: RoastmateSpacing.md),
              Expanded(
                child: _buildMetricItem(
                  Icons.thermostat_outlined,
                  "Suhu Air",
                  rec.tempC,
                  rec.tempCSub,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: RoastmateSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildMetricItem(
                  Icons.blur_circular_outlined,
                  "Tingkat Gilingan",
                  rec.grind,
                  rec.grindSub,
                ),
              ),
              const SizedBox(width: RoastmateSpacing.md),
              Expanded(
                child: _buildMetricItem(
                  Icons.timer_outlined,
                  "Target Waktu",
                  rec.targetTime,
                  rec.targetTimeSub,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(
    IconData icon,
    String label,
    String value,
    String sub,
  ) {
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
              Flexible(
                child: Text(
                  label,
                  style: RoastmateText.labelSm.copyWith(
                    color: RoastmateColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: RoastmateText.titleMd.copyWith(
              color: RoastmateColors.textPrimary,
            ),
          ),
          Text(
            sub,
            style: RoastmateText.bodySm.copyWith(
              color: RoastmateColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context) {
    final enabled = methodId != null;
    final color = enabled ? RoastmateColors.primary : RoastmateColors.iconMuted;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? () => context.push('/brewing/$methodId') : null,
        icon: Icon(Icons.arrow_forward, size: 16, color: color),
        label: Text(
          enabled ? "Lihat Cara Penyajian" : "Detail Resep Belum Tersedia",
          style: RoastmateText.labelLg.copyWith(color: color),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled
              ? RoastmateColors.espressoSoft
              : RoastmateColors.surfaceContainer,
          foregroundColor: RoastmateColors.primary,
          elevation: 0,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RoastmateRadius.small),
          ),
        ),
      ),
    );
  }
}
