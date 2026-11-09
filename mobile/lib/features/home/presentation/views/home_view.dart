import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/widgets/roastmate_app_header.dart';
import '../../../../shared/enums/indicative_grade.dart';
import '../../domain/entities/home_summary.dart';
import '../viewmodels/home_view_model.dart';

// ============================================================
// Design System: Warm Technical Minimalism (token di core/theme)
// ============================================================
// Primary:   #5A382C   Secondary: #8B5E3C   Tertiary: #5E6B4A
// Font:      Inter (diatur global via theme)
//
// Data: seluruh angka berasal dari SQLite (tabel `analyses`) lewat
// HomeViewModel. Tidak ada data contoh di file ini.
// ============================================================

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const Color _primary = RoastmateColors.primary;
  static const Color _secondary = RoastmateColors.secondary;
  static const Color _tertiary = RoastmateColors.tertiary;
  static const Color _neutral = RoastmateColors.textSecondary;
  static const Color _background = RoastmateColors.background;
  static const Color _cardBg = RoastmateColors.surfaceContainer;
  static const Color _cardWhite = RoastmateColors.surface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: _background,
      appBar: const RoastmateAppHeader(subtitle: 'Beranda'),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: () => ref.read(homeViewModelProvider.notifier).load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 24),
              if (state.isLoading)
                _buildLoading()
              else if (state.hasError)
                _buildError(ref, state.errorMessage!)
              else if (state.summary.isEmpty)
                _buildEmptyState(context)
              else
                _buildSummary(context, state.summary),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATE: LOADING
  // ============================================================
  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Center(child: CircularProgressIndicator(color: _primary)),
    );
  }

  // ============================================================
  // STATE: ERROR
  // ============================================================
  Widget _buildError(WidgetRef ref, String message) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.error_outline, color: _secondary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Riwayat analisis gagal dibaca',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Riwayat disimpan lokal di perangkat ini. Coba muat ulang; '
                'bila masih gagal, buka kembali aplikasi.',
                style: TextStyle(fontSize: 12, color: _neutral, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: _neutral),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.read(homeViewModelProvider.notifier).load(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _secondary, width: 1.5),
                  minimumSize: const Size(48, 48),
                ),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildInfoBox(),
      ],
    );
  }

  // ============================================================
  // STATE: EMPTY
  // ============================================================
  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        _buildScanBanner(context),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            children: [
              Icon(Icons.inbox_outlined, size: 40, color: _secondary),
              SizedBox(height: 12),
              Text(
                'Belum ada analisis tersimpan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _primary,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Scan batch pertamamu untuk melihat ringkasan kualitas di '
                'sini. Ringkasan hanya dihitung dari biji yang terlihat '
                'pada foto.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: _neutral, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildInfoBox(),
      ],
    );
  }

  // ============================================================
  // STATE: ADA DATA
  // ============================================================
  Widget _buildSummary(BuildContext context, HomeSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompositionCard(summary),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTotalAnalysisCard(summary.totalAnalyses)),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAverageScoreCard(summary.averageScore, summary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildScanBanner(context),
        const SizedBox(height: 24),
        _buildRecentAnalysisHeader(context),
        const SizedBox(height: 16),
        _buildRecentAnalysisList(context, summary.recentAnalyses),
        const SizedBox(height: 24),
        _buildInfoBox(),
      ],
    );
  }

  // ============================================================
  // GREETING
  // ============================================================
  Widget _buildGreeting() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat datang kembali',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Siap untuk grading batch hari ini?',
                style: TextStyle(fontSize: 14, color: _neutral),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.tune, color: _primary),
        ),
      ],
    );
  }

  // ============================================================
  // COMPOSITION CARD
  // ============================================================
  Widget _buildCompositionCard(HomeSummary summary) {
    final arabicaShare = summary.shareOf(SpeciesLabels.arabica);
    final mixedCount = summary.countOf(SpeciesLabels.mixed);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline, color: _primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Komposisi Jenis Biji',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total ${summary.totalAnalyses} Batch',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: arabicaShare,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFFCBBFB5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          _primary,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(arabicaShare * 100).round()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _primary,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Arabica',
                          style: TextStyle(fontSize: 10, color: _neutral),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendRow(
                      _primary,
                      SpeciesLabels.arabica,
                      summary,
                    ),
                    const SizedBox(height: 12),
                    _buildLegendRow(
                      const Color(0xFFCBBFB5),
                      SpeciesLabels.robusta,
                      summary,
                    ),
                    if (mixedCount > 0) ...[
                      const SizedBox(height: 12),
                      _buildLegendRow(_secondary, SpeciesLabels.mixed, summary),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String species, HomeSummary summary) {
    final count = summary.countOf(species);
    final percentage = (summary.shareOf(species) * 100).round();

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            species,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: _primary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _primary,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($percentage%)',
          style: const TextStyle(color: _neutral, fontSize: 12),
        ),
      ],
    );
  }

  // ============================================================
  // TOTAL ANALYSIS CARD
  // ============================================================
  Widget _buildTotalAnalysisCard(int totalAnalyses) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Analisis',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _neutral,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: _cardBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_box_outlined,
                  color: _secondary,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$totalAnalyses',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Batch terkurasi',
            style: TextStyle(fontSize: 12, color: _neutral),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AVERAGE SCORE CARD
  // ============================================================
  Widget _buildAverageScoreCard(double averageScore, HomeSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rata-rata Nilai',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _neutral,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _tertiary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_border,
                  color: _tertiary,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                averageScore.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                ),
              ),
              const Text(
                ' /100',
                style: TextStyle(
                  fontSize: 12,
                  color: _neutral,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _tertiary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'GRADE: ${summary.averageGrade.label.toUpperCase()}',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: _tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SCAN BANNER
  // ============================================================
  Widget _buildScanBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5A382C), Color(0xFF3D2419)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -10,
            child: Icon(
              Icons.camera_alt_outlined,
              size: 120,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Computer Vision AI',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Scan Batch Baru',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Analisis biji yang terlihat pada satu foto\n'
                'secara akurat dan objektif.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/scan/setup'),
                  icon: const Icon(Icons.camera_alt, color: _primary),
                  label: const Text(
                    'Mulai Scan',
                    style: TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECENT ANALYSIS HEADER
  // ============================================================
  Widget _buildRecentAnalysisHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Analisis Terakhir',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
        InkWell(
          onTap: () => context.go('/history'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _secondary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, color: _secondary, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RECENT ANALYSIS LIST
  // ============================================================
  Widget _buildRecentAnalysisList(
    BuildContext context,
    List<HomeAnalysisSummary> items,
  ) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _buildAnalysisCard(context, items[i]),
          if (i < items.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildAnalysisCard(BuildContext context, HomeAnalysisSummary item) {
    final gradeTokens =
        RoastmateColors.grade[item.grade.name] ??
        RoastmateColors.grade['standard']!;

    return Material(
      color: _cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        // Layar Detail Inspeksi masih memakai data mock; sampai bisa membaca
        // SQLite, kartu mengarah ke tab Analisis.
        onTap: () => context.go('/history'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.coffee, color: _secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _primary,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: gradeTokens['container'],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.grade.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: gradeTokens['color'],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.shortDateLabel} • ${item.species}',
                      style: const TextStyle(fontSize: 12, color: _neutral),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.grid_on,
                              size: 12,
                              color: _neutral,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.visibleBeans} biji terlihat',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _neutral,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              'Skor: ',
                              style: TextStyle(fontSize: 12, color: _neutral),
                            ),
                            Text(
                              '${item.qualityScore}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _primary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFO BOX
  // ============================================================
  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: _secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Roastmate hanya menilai biji yang terlihat pada permukaan foto.',
              style: TextStyle(
                color: _primary.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
