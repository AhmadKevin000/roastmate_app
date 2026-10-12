import 'package:flutter/material.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../../../../shared/models/analysis_result.dart';
import '../../../brew/data/sources/method_lookup.dart';
import 'brew_method_tab_content.dart';

/// Kartu rekomendasi seduh dengan **tab per metode**.
///
/// Tab pertama (default aktif) adalah metode yang direkomendasikan; opsi
/// alternatif tersembunyi di tab lain sampai dipilih. Setiap tab punya CTA
/// menuju Detail Resep.
class BrewRecommendationCard extends StatefulWidget {
  final InspectionResult result;

  const BrewRecommendationCard({super.key, required this.result});

  @override
  State<BrewRecommendationCard> createState() => _BrewRecommendationCardState();
}

class _BrewRecommendationCardState extends State<BrewRecommendationCard>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  int get _tabCount => 1 + widget.result.alternatives.length;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  @override
  void didUpdateWidget(covariant BrewRecommendationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result.alternatives.length !=
        widget.result.alternatives.length) {
      _tabController?.removeListener(_onTabChanged);
      _tabController?.dispose();
      _createController();
    }
  }

  void _createController() {
    _tabController = TabController(length: _tabCount, vsync: this)
      ..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    // Ganti isi tab saat indeks berubah.
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

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
        methodId: resolveMethodId(rec.methodTitle),
      ),
      for (final alt in widget.result.alternatives)
        _BrewTab(
          label: _shortMethodLabel(alt.title, 'Alternatif'),
          methodId: resolveMethodId(alt.title),
        ),
    ];

    final controller = _tabController!;
    final index = controller.index.clamp(0, tabs.length - 1);

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
          TabBar(
            controller: controller,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: RoastmateColors.primary,
            unselectedLabelColor: RoastmateColors.textSecondary,
            labelStyle: RoastmateText.labelLg,
            unselectedLabelStyle: RoastmateText.labelLg,
            indicatorColor: RoastmateColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: RoastmateColors.borderDefault,
            tabs: [for (final tab in tabs) Tab(text: tab.label)],
          ),
          const SizedBox(height: RoastmateSpacing.lg),
          BrewMethodTabContent(
            primary: index == 0 ? rec : null,
            alternative: index == 0
                ? null
                : widget.result.alternatives[index - 1],
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

/// Satu entri tab: label + `methodId` katalog (bila dikenali).
class _BrewTab {
  final String label;
  final String? methodId;

  const _BrewTab({required this.label, this.methodId});
}
