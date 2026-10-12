import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/widgets/roastmate_app_header.dart';
import '../../../analysis/data/sources/mock_analysis_history.dart';
import '../../../analysis/domain/entities/analysis_history_item.dart';

// ============================================================
// Design System: Warm Technical Minimalism (token di core/theme)
// ============================================================
// Primary:   #5A382C   Secondary: #8B5E3C   Tertiary: #5E6B4A
// Font:      Inter (diatur global via theme)
// ============================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // -- Color constants (selaras core/theme) --
  static const Color _primary = RoastmateColors.primary;
  static const Color _secondary = RoastmateColors.secondary;
  static const Color _tertiary = RoastmateColors.tertiary;
  static const Color _neutral = RoastmateColors.textSecondary;
  static const Color _background = RoastmateColors.background;
  static const Color _cardBg = RoastmateColors.surfaceContainer;
  static const Color _cardWhite = RoastmateColors.surface;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: const RoastmateAppHeader(subtitle: 'Beranda'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(),
            const SizedBox(height: 24),
            _buildCompositionCard(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTotalAnalysisCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildAverageScoreCard()),
              ],
            ),
            const SizedBox(height: 16),
            _buildScanBanner(context),
            const SizedBox(height: 24),
            _buildRecentAnalysisHeader(context),
            const SizedBox(height: 16),
            _buildRecentAnalysisList(context),
            const SizedBox(height: 24),
            _buildInfoBox(),
          ],
        ),
      ),
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
  Widget _buildCompositionCard() {
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
                child: const Text(
                  'Total 42 Batch',
                  style: TextStyle(
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
                        value: 0.68,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFFCBBFB5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          _primary,
                        ),
                      ),
                    ),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '68%',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _primary,
                            fontSize: 16,
                          ),
                        ),
                        Text(
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
                    _buildLegendRow(_primary, 'Arabica', '29', '(68%)'),
                    const SizedBox(height: 12),
                    _buildLegendRow(
                      const Color(0xFFCBBFB5),
                      'Robusta',
                      '13',
                      '(32%)',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(
    Color color,
    String label,
    String value,
    String percentage,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: _primary,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _primary,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        Text(percentage, style: const TextStyle(color: _neutral, fontSize: 12)),
      ],
    );
  }

  // ============================================================
  // TOTAL ANALYSIS CARD
  // ============================================================
  Widget _buildTotalAnalysisCard() {
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
          const Text(
            '42',
            style: TextStyle(
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
  Widget _buildAverageScoreCard() {
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
                child: Icon(Icons.star_border, color: _tertiary, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '84.5',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                ),
              ),
              Text(
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
              'GRADE: PREMIUM',
              style: TextStyle(
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
                'Analisis biji yang terlihat pada satu foto\nsecara akurat dan objektif.',
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
                Icon(Icons.chevron_right, color: _secondary, size: 18),
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
  Widget _buildRecentAnalysisList(BuildContext context) {
    // Sumber sama dengan tab Analisis agar judul/skor kartu cocok dengan isi
    // Detail Inspeksi yang dibuka.
    final items = mockAnalysisHistory.take(3).toList();

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _buildAnalysisCard(context, items[i]),
          if (i < items.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildAnalysisCard(BuildContext context, AnalysisHistoryItem item) {
    final gradeTokens =
        RoastmateColors.grade[item.grade.name] ??
        RoastmateColors.grade['standard']!;

    return Material(
      color: _cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push(
          '/result/${Uri.encodeComponent(item.detail.batchLabel)}',
          extra: item.detail,
        ),
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
                child: Icon(Icons.coffee, color: _secondary),
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
                            item.batchName,
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
                            gradeShortLabel(item.grade),
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
