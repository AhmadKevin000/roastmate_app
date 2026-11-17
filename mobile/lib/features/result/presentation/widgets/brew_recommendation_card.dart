import 'package:flutter/material.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../../../../shared/models/analysis_result.dart';
import '../../../brew/data/sources/method_lookup.dart';
import 'brew_method_tab_content.dart';

/// Kartu rekomendasi seduh dengan **navigasi tab berupa chip bertumpuk ke
/// bawah** (scrollable bersama halaman).
///
/// Chip pertama adalah metode yang direkomendasikan (ditandai badge
/// "Direkomendasikan"); opsi alternatif tersedia di chip lain. Isi tiap tab
/// memiliki struktur identik.
class BrewRecommendationCard extends StatefulWidget {
  final InspectionResult result;

  const BrewRecommendationCard({super.key, required this.result});

  @override
  State<BrewRecommendationCard> createState() => _BrewRecommendationCardState();
}

class _BrewRecommendationCardState extends State<BrewRecommendationCard> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final rec = widget.result.recommendation;

    if (rec == null) {
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
          style: RoastmateText.bodyLg.copyWith(
            color: RoastmateColors.textPrimary,
          ),
        ),
      );
    }

    final tabs = <_BrewTab>[
      _BrewTab(
        label: _shortMethodLabel(rec.methodTitle, 'Utama'),
        info: rec.toInfo(),
        methodId: resolveMethodId(rec.methodTitle),
        recommended: true,
      ),
      for (final alt in widget.result.alternatives)
        _BrewTab(
          label: _shortMethodLabel(alt.title, 'Alternatif'),
          info: alt.toInfo(),
          methodId: resolveMethodId(alt.title),
          recommended: false,
        ),
    ];

    final index = _selected.clamp(0, tabs.length - 1);

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
              const Icon(
                Icons.coffee_maker_outlined,
                size: 16,
                color: RoastmateColors.textSecondary,
              ),
              const SizedBox(width: RoastmateSpacing.sm),
              Flexible(
                child: Text(
                  "REKOMENDASI SEDUH TERKALIBRASI",
                  style: RoastmateText.labelSm.copyWith(
                    color: RoastmateColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.md),
          // Navigasi tab: chip bertumpuk ke bawah (bukan menyamping).
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < tabs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: RoastmateSpacing.sm),
                  child: _MethodChip(
                    label: tabs[i].label,
                    recommended: tabs[i].recommended,
                    selected: i == index,
                    onTap: () => setState(() => _selected = i),
                  ),
                ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.md),
          BrewMethodTabContent(
            info: tabs[index].info,
            methodId: tabs[index].methodId,
          ),
        ],
      ),
    );
  }

  /// Nama metode dipendekkan untuk label tab (segmen sebelum pemisah pertama).
  static String _shortMethodLabel(String title, String fallback) {
    const separators = [' — ', ' – ', ' - ', ' (', ' / ', ': '];
    final trimmed = title.trim();
    var cut = trimmed.length;
    for (final sep in separators) {
      final idx = trimmed.indexOf(sep);
      if (idx > 0 && idx < cut) cut = idx;
    }
    final label = trimmed.substring(0, cut).trim();
    return label.isEmpty ? fallback : label;
  }
}

/// Chip navigasi tab (rounded seperti tombol).
class _MethodChip extends StatelessWidget {
  final String label;
  final bool recommended;
  final bool selected;
  final VoidCallback onTap;

  const _MethodChip({
    required this.label,
    required this.recommended,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(RoastmateRadius.small);

    return Material(
      color: selected
          ? RoastmateColors.espressoSoft
          : RoastmateColors.surfaceContainer,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RoastmateSpacing.lg,
            vertical: RoastmateSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? RoastmateColors.primary
                  : RoastmateColors.borderDefault,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: RoastmateSpacing.sm,
            runSpacing: RoastmateSpacing.xs,
            children: [
              Text(
                label,
                style: RoastmateText.labelLg.copyWith(
                  color: selected
                      ? RoastmateColors.primary
                      : RoastmateColors.textSecondary,
                ),
              ),
              if (recommended) const _RecommendedBadge(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge kecil penanda metode yang direkomendasikan.
class _RecommendedBadge extends StatelessWidget {
  const _RecommendedBadge();

  @override
  Widget build(BuildContext context) {
    final tokens = RoastmateColors.grade['specialty']!;
    final color = tokens['color']!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tokens['container'],
        borderRadius: BorderRadius.circular(RoastmateRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            'Direkomendasikan',
            style: RoastmateText.labelSm.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Satu entri tab: label, isi seragam, dan `methodId` katalog (bila dikenali).
class _BrewTab {
  final String label;
  final BrewMethodInfo info;
  final String? methodId;
  final bool recommended;

  const _BrewTab({
    required this.label,
    required this.info,
    required this.methodId,
    required this.recommended,
  });
}
