import 'package:flutter/material.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../../../shared/models/analysis_result.dart';
import '../viewmodels/result_view_model.dart';
import '../widgets/inspection_header.dart';
import '../widgets/quality_score_card.dart';
import '../widgets/brew_recommendation_card.dart';
import '../widgets/personal_rating_card.dart';
import '../widgets/visual_evidence_card.dart';
import '../widgets/composition_breakdown_card.dart';
import '../widgets/disclaimer_banner.dart';
import '../../../../core/widgets/roastmate_app_bar.dart';

/// Layar Detail Inspeksi (Plan 3): data dibaca **dari SQLite per
/// [analysisId]** (join knowledge base), bukan dari `state.extra`.
///
/// [fallback] dipakai saat [analysisId] null (route `draft` setelah scan)
/// atau baca DB gagal — data in-memory alur scan tetap tampil (AC-04).
class InspectionDetailScreen extends StatefulWidget {
  /// Id baris `analyses`; null bila belum tersimpan di DB.
  final int? analysisId;

  /// Data in-memory cadangan (route extra, alur scan).
  final InspectionResult? fallback;

  const InspectionDetailScreen({
    super.key,
    this.analysisId,
    this.fallback,
  });

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  late final ResultViewModel _viewModel;
  late final VoidCallback _removeListener;

  @override
  void initState() {
    super.initState();
    _viewModel = ResultViewModel(
      analysisId: widget.analysisId,
      fallback: widget.fallback,
    );
    _removeListener = _viewModel.addListener(
      (_) {
        if (mounted) setState(() {});
      },
      fireImmediately: false,
    );
    _viewModel.load();
  }

  @override
  void dispose() {
    _removeListener();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoastmateColors.background,
      appBar: const RoastmateAppBar(title: 'Detail Inspeksi'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final state = _viewModel.viewState;

    if (state.loading) {
      return const Center(
        child: CircularProgressIndicator(color: RoastmateColors.primary),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!, style: RoastmateText.bodyLg),
            const SizedBox(height: RoastmateSpacing.md),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: RoastmateColors.primary,
                foregroundColor: RoastmateColors.surface,
              ),
              onPressed: () => _viewModel.load(),
              child: const Text("Coba lagi"),
            ),
          ],
        ),
      );
    }

    final detail = state.content!;
    final result = detail.displayResult;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth >= 600
                      ? (constraints.maxWidth > 720
                            ? (constraints.maxWidth - 720) / 2
                            : 0)
                      : 0,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: RoastmateSpacing.lg),
                    InspectionHeader(
                      batchLabel: result.batchLabel,
                      batchName: result.batchName,
                      analyzedAgo: result.analyzedAgo,
                    ),
                    const SizedBox(height: RoastmateSpacing.xl),
                    QualityScoreCard(result: result),
                    const SizedBox(height: RoastmateSpacing.xl),
                    if (result.roast.toLowerCase() != 'green' &&
                        result.recommendation != null)
                      BrewRecommendationCard(result: result),
                    if (result.roast.toLowerCase() == 'green' ||
                        result.recommendation == null)
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: RoastmateSpacing.lg,
                        ),
                        padding: const EdgeInsets.all(RoastmateSpacing.lg),
                        decoration: BoxDecoration(
                          color: RoastmateColors.statusInfoContainer,
                          borderRadius: BorderRadius.circular(
                            RoastmateRadius.large,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info,
                              color: RoastmateColors.statusInfo,
                            ),
                            const SizedBox(width: RoastmateSpacing.md),
                            Expanded(
                              child: Text(
                                "Biji masih Green — perlu roasting, tanpa parameter seduh.",
                                style: RoastmateText.bodyLg.copyWith(
                                  color: RoastmateColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: RoastmateSpacing.xl),
                    _SummaryCard(text: detail.summaryText),
                    const SizedBox(height: RoastmateSpacing.xl),
                    PersonalRatingCard(
                      ratingKey: result.batchLabel,
                      analysisId: widget.analysisId ??
                          (detail.analysisId > 0 ? detail.analysisId : null),
                      initialStars: detail.personalRating,
                      initialNote: detail.personalRatingNote,
                    ),
                    const SizedBox(height: RoastmateSpacing.xl),
                    VisualEvidenceCard(
                      result: result,
                      imagePath: detail.imagePath,
                    ),
                    const SizedBox(height: RoastmateSpacing.xl),
                    CompositionBreakdownCard(result: result),
                    const SizedBox(height: RoastmateSpacing.xl),
                    const DisclaimerBanner(),
                    const SizedBox(height: RoastmateSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Kartu ringkasan analisis — `summaryText` di-generate saat baca dari DB
/// (D-20), jadi di-render di layar, bukan disimpan.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.text});

  final String text;

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
            children: [
              const Icon(
                Icons.summarize_outlined,
                size: 16,
                color: RoastmateColors.textSecondary,
              ),
              const SizedBox(width: RoastmateSpacing.sm),
              Text(
                "RINGKASAN ANALISIS",
                style: RoastmateText.labelSm.copyWith(
                  color: RoastmateColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.md),
          Text(
            text,
            style: RoastmateText.bodyLg.copyWith(
              color: RoastmateColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
