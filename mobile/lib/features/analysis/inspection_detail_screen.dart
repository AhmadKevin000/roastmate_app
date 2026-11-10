import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/roastmate_colors.dart';
import '../../core/roastmate_text.dart';
import '../../core/roastmate_spacing.dart';
import '../../core/roastmate_radius.dart';
import '../../domain/inspection_result.dart';
import 'providers/analysis_provider.dart';
import 'widgets/inspection_header.dart';
import 'widgets/quality_score_card.dart';
import 'widgets/brew_recommendation_card.dart';
import 'widgets/visual_evidence_card.dart';
import 'widgets/composition_breakdown_card.dart';
import 'widgets/disclaimer_banner.dart';
import 'widgets/roastmate_bottom_nav.dart';

enum ViewState { loading, content, error }

class InspectionDetailScreen extends ConsumerStatefulWidget {
  final InspectionResult? result;
  final int? analysisId;
  final ViewState initialState;

  const InspectionDetailScreen({
    super.key,
    this.result,
    this.analysisId,
    this.initialState = ViewState.content,
  });

  @override
  ConsumerState<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends ConsumerState<InspectionDetailScreen> {
  late ViewState _state;
  InspectionResult? _currentResult;
  bool _isSaving = false;
  int? _savedId;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _currentResult = widget.result;
    _savedId = widget.result?.id ?? widget.analysisId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  Future<void> _initData() async {
    final repo = ref.read(analysisRepositoryProvider);

    if (widget.analysisId != null) {
      setState(() => _state = ViewState.loading);
      try {
        final res = await repo.getInspectionById(widget.analysisId!);
        if (mounted) {
          if (res != null) {
            setState(() {
              _currentResult = res;
              _savedId = res.id;
              _state = ViewState.content;
            });
          } else {
            setState(() => _state = ViewState.error);
          }
        }
      } catch (e) {
        if (mounted) setState(() => _state = ViewState.error);
      }
    } else if (_currentResult != null) {
      // Pastikan seed data / initial check ke SQLite
      try {
        await repo.ensureSeedData(_currentResult!);
        if (_savedId == null) {
          // Cek apakah data ini sudah tersimpan
          final count = await repo.countInspections();
          if (count > 0 && mounted) {
            final latest = await repo.getAllInspections();
            if (latest.isNotEmpty && mounted) {
              setState(() {
                _savedId = latest.first.id;
              });
            }
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _handleSaveToDatabase() async {
    if (_currentResult == null || _isSaving) return;

    setState(() => _isSaving = true);
    final repo = ref.read(analysisRepositoryProvider);

    try {
      final newId = await repo.saveInspection(_currentResult!);
      if (mounted) {
        setState(() {
          _isSaving = false;
          _savedId = newId;
          _currentResult = _currentResult!.copyWith(id: newId);
        });
        // Invalidate provider agar daftar riwayat ter-update
        ref.invalidate(allAnalysesProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: RoastmateColors.statusSuccess,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: RoastmateSpacing.md),
                Expanded(
                  child: Text(
                    "Berhasil disimpan ke SQLite Lokal (ID: #$newId)",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: RoastmateColors.statusError,
            content: Text("Gagal menyimpan ke SQLite: $e"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
          icon: const Icon(Icons.arrow_back, color: RoastmateColors.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Column(
          children: [
            Text(
              "Detail Inspeksi",
              style: RoastmateText.titleLg.copyWith(color: RoastmateColors.textPrimary),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storage_rounded,
                  size: 12,
                  color: _savedId != null ? RoastmateColors.statusSuccess : RoastmateColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _savedId != null ? "Tersimpan di SQLite (#$_savedId)" : "Belum Tersimpan",
                  style: RoastmateText.labelSm.copyWith(
                    color: _savedId != null ? RoastmateColors.statusSuccess : RoastmateColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Simpan ke Database SQLite",
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: RoastmateColors.primary),
                  )
                : Icon(
                    _savedId != null ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                    color: _savedId != null ? RoastmateColors.primary : RoastmateColors.textSecondary,
                  ),
            onPressed: _handleSaveToDatabase,
          ),
          Padding(
            padding: const EdgeInsets.only(right: RoastmateSpacing.lg),
            child: CircleAvatar(
              backgroundColor: RoastmateColors.primary,
              radius: 16,
              child: const Icon(Icons.person, size: 20, color: RoastmateColors.surface),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: RoastmateBottomNav(
        currentIndex: 1, // Analisis tab active
        onTap: (index) {
          if (index == 1) {
            // Sudah di detail analisis
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Sedang membuka Detail Inspeksi")),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Tab $index dipilih")),
            );
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_state == ViewState.loading) {
      return const Center(child: CircularProgressIndicator(color: RoastmateColors.primary));
    }

    if (_state == ViewState.error || _currentResult == null) {
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
                _initData();
              },
              child: const Text("Coba lagi"),
            ),
          ],
        ),
      );
    }

    final result = _currentResult!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth >= 600 ? (constraints.maxWidth > 720 ? (constraints.maxWidth - 720) / 2 : 0) : 0,
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
                    if (result.roast.toLowerCase() != 'green' && result.recommendation != null)
                      BrewRecommendationCard(result: result),
                    if (result.roast.toLowerCase() == 'green' || result.recommendation == null)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: RoastmateSpacing.lg),
                        padding: const EdgeInsets.all(RoastmateSpacing.lg),
                        decoration: BoxDecoration(
                          color: RoastmateColors.statusInfoContainer,
                          borderRadius: BorderRadius.circular(RoastmateRadius.large),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: RoastmateColors.statusInfo),
                            const SizedBox(width: RoastmateSpacing.md),
                            Expanded(
                              child: Text(
                                "Biji masih Green — perlu roasting, tanpa parameter seduh.",
                                style: RoastmateText.bodyLg.copyWith(color: RoastmateColors.textPrimary),
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
