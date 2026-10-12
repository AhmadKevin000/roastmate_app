import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../../../../shared/models/analysis_result.dart';

/// Isi satu tab pada kartu rekomendasi seduh.
///
/// Struktur **identik** untuk semua tab (utama maupun alternatif): judul +
/// deskripsi + empat kartu parameter seduh + CTA ke Detail Resep.
class BrewMethodTabContent extends StatelessWidget {
  final BrewMethodInfo info;

  /// `methodId` katalog (untuk CTA). Null bila metode tidak dikenal katalog.
  final String? methodId;

  const BrewMethodTabContent({super.key, required this.info, this.methodId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          info.title,
          style: RoastmateText.titleLg.copyWith(
            color: RoastmateColors.textPrimary,
          ),
        ),
        const SizedBox(height: RoastmateSpacing.sm),
        Text(
          info.description,
          style: RoastmateText.bodyMd.copyWith(
            color: RoastmateColors.textSecondary,
          ),
        ),
        const SizedBox(height: RoastmateSpacing.lg),
        _buildMetrics(),
        const SizedBox(height: RoastmateSpacing.lg),
        _buildCta(context),
      ],
    );
  }

  Widget _buildMetrics() {
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
                  info.ratio,
                  info.ratioSub,
                ),
              ),
              const SizedBox(width: RoastmateSpacing.md),
              Expanded(
                child: _buildMetricItem(
                  Icons.thermostat_outlined,
                  "Suhu Air",
                  info.tempC,
                  info.tempCSub,
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
                  info.grind,
                  info.grindSub,
                ),
              ),
              const SizedBox(width: RoastmateSpacing.md),
              Expanded(
                child: _buildMetricItem(
                  Icons.timer_outlined,
                  "Target Waktu",
                  info.targetTime,
                  info.targetTimeSub,
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
