import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/roastmate_colors.dart';
import '../core/roastmate_text.dart';
import '../core/roastmate_spacing.dart';
import '../core/roastmate_radius.dart';
import '../domain/inspection_result.dart';
import '../features/analysis/inspection_detail_screen.dart';
import '../features/analysis/providers/analysis_provider.dart';

class AnalysisPage extends ConsumerWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysesAsync = ref.watch(allAnalysesProvider);

    return Scaffold(
      backgroundColor: RoastmateColors.background,
      appBar: AppBar(
        title: Text(
          'Riwayat Analisis',
          style: RoastmateText.titleLg.copyWith(color: RoastmateColors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: RoastmateColors.primary),
            tooltip: 'Segarkan',
            onPressed: () {
              ref.invalidate(allAnalysesProvider);
            },
          ),
        ],
      ),
      body: analysesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: RoastmateColors.primary),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(RoastmateSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: RoastmateColors.statusError),
                const SizedBox(height: RoastmateSpacing.md),
                Text('Gagal memuat riwayat: $err', textAlign: TextAlign.center, style: RoastmateText.bodyMd),
                const SizedBox(height: RoastmateSpacing.lg),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: RoastmateColors.primary),
                  onPressed: () => ref.invalidate(allAnalysesProvider),
                  child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.coffee_outlined, size: 64, color: RoastmateColors.textSecondary),
                  const SizedBox(height: RoastmateSpacing.md),
                  Text('Belum ada riwayat analisis', style: RoastmateText.titleMd),
                  const SizedBox(height: RoastmateSpacing.sm),
                  Text('Hasil analisis scan akan tersimpan di SQLite lokal.', style: RoastmateText.bodySm),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: RoastmateColors.primary,
            onRefresh: () async {
              ref.invalidate(allAnalysesProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(RoastmateSpacing.lg),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: RoastmateSpacing.md),
              itemBuilder: (context, index) {
                final item = list[index];
                return _buildAnalysisCard(context, ref, item);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalysisCard(BuildContext context, WidgetRef ref, InspectionResult item) {
    return InkWell(
      borderRadius: BorderRadius.circular(RoastmateRadius.medium),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InspectionDetailScreen(
              analysisId: item.id,
              result: item,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(RoastmateSpacing.lg),
        decoration: BoxDecoration(
          color: RoastmateColors.surface,
          borderRadius: BorderRadius.circular(RoastmateRadius.medium),
          border: Border.all(color: RoastmateColors.borderDefault),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Score circle
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: _getScoreColor(item.qualityScore).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${item.qualityScore}',
                  style: RoastmateText.titleLg.copyWith(
                    color: _getScoreColor(item.qualityScore),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: RoastmateSpacing.lg),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.batchName,
                          style: RoastmateText.titleMd.copyWith(color: RoastmateColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: RoastmateColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(RoastmateRadius.small),
                        ),
                        child: Text(
                          item.species,
                          style: RoastmateText.labelSm.copyWith(color: RoastmateColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.batchLabel} • ${item.roast} Roast • ${item.visibleBeans} Biji',
                    style: RoastmateText.bodySm.copyWith(color: RoastmateColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: RoastmateColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        item.analyzedAgo,
                        style: RoastmateText.labelSm.copyWith(color: RoastmateColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: RoastmateColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return RoastmateColors.statusSuccess;
    if (score >= 70) return RoastmateColors.primary;
    if (score >= 50) return RoastmateColors.statusWarning;
    return RoastmateColors.statusError;
  }
}
