import 'package:flutter/material.dart';
import '../../core/roastmate_colors.dart';
import '../../core/roastmate_text.dart';
import '../../core/roastmate_spacing.dart';
import '../../core/roastmate_radius.dart';
import '../../domain/inspection_result.dart';
import 'widgets/inspection_header.dart';
import 'widgets/quality_score_card.dart';
import 'widgets/brew_recommendation_card.dart';
import 'widgets/visual_evidence_card.dart';
import 'widgets/composition_breakdown_card.dart';
import 'widgets/disclaimer_banner.dart';
import 'widgets/roastmate_bottom_nav.dart';

enum ViewState { loading, content, error }

class InspectionDetailScreen extends StatefulWidget {
  final InspectionResult? result;
  final ViewState initialState;

  const InspectionDetailScreen({
    Key? key,
    this.result,
    this.initialState = ViewState.content,
  }) : super(key: key);

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  late ViewState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoastmateColors.background,
      appBar: AppBar(
        backgroundColor: RoastmateColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: RoastmateColors.textPrimary,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          "Detail Inspeksi",
          style: RoastmateText.titleLg.copyWith(
            color: RoastmateColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: RoastmateSpacing.lg),
            child: CircleAvatar(
              backgroundColor: RoastmateColors.primary,
              radius: 16,
              child: const Icon(
                Icons.person,
                size: 20,
                color: RoastmateColors.surface,
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_state == ViewState.loading) {
      return const Center(
        child: CircularProgressIndicator(color: RoastmateColors.primary),
      );
    }

    if (_state == ViewState.error || widget.result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Gagal memuat detail inspeksi", style: RoastmateText.bodyLg),
            const SizedBox(height: RoastmateSpacing.md),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: RoastmateColors.primary,
                foregroundColor: RoastmateColors.surface,
              ),
              onPressed: () {
                setState(() => _state = ViewState.content);
              },
              child: const Text("Coba lagi"),
            ),
          ],
        ),
      );
    }

    final result = widget.result!;

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
                    VisualEvidenceCard(result: result),
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
