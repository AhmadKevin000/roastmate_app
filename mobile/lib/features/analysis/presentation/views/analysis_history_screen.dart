import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../data/sources/mock_analysis_history.dart';
import '../../domain/entities/analysis_history_item.dart';
import '../widgets/history_filter_bar.dart';
import '../widgets/history_card.dart';
import '../widgets/history_export_card.dart';
import '../../../../core/widgets/roastmate_app_header.dart';

/// Layar Riwayat Analisis (tab Analisis).
///
/// Saat ini memakai data dummy ([mockAnalysisHistory]); pengambilan dari SQLite
/// akan ditambahkan lewat repository/controller terpisah.
class AnalysisHistoryScreen extends StatefulWidget {
  /// Daftar item riwayat. Bila null, memakai [mockAnalysisHistory].
  final List<AnalysisHistoryItem>? items;

  const AnalysisHistoryScreen({super.key, this.items});

  @override
  State<AnalysisHistoryScreen> createState() => _AnalysisHistoryScreenState();
}

class _AnalysisHistoryScreenState extends State<AnalysisHistoryScreen> {
  static const List<String> _filterOptions = [
    'Semua',
    'Arabica',
    'Robusta',
    'Mixed',
  ];

  String _selectedFilter = 'Semua';

  List<AnalysisHistoryItem> get _allItems =>
      widget.items ?? mockAnalysisHistory;

  List<AnalysisHistoryItem> get _filteredItems {
    if (_selectedFilter == 'Semua') return _allItems;
    return _allItems.where((item) => item.species == _selectedFilter).toList();
  }

  Map<String, int> get _filterCounts {
    final items = _allItems;
    return {
      'Semua': items.length,
      'Arabica': items.where((item) => item.species == 'Arabica').length,
      'Robusta': items.where((item) => item.species == 'Robusta').length,
      'Mixed': items.where((item) => item.species == 'Mixed').length,
    };
  }

  void _openDetail(AnalysisHistoryItem item) {
    context.push(
      '/history/${Uri.encodeComponent(item.detail.batchLabel)}',
      extra: item.detail,
    );
  }

  void _onExportCsv() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ekspor CSV akan tersedia di versi berikutnya'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: RoastmateColors.background,
      appBar: const RoastmateAppHeader(subtitle: 'Analisis'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleRow(),
            const SizedBox(height: RoastmateSpacing.lg),
            HistoryFilterBar(
              options: _filterOptions,
              selected: _selectedFilter,
              counts: _filterCounts,
              onSelected: (value) => setState(() => _selectedFilter = value),
            ),
            const SizedBox(height: RoastmateSpacing.lg),
            if (items.isEmpty)
              _buildEmptyState()
            else
              for (int i = 0; i < items.length; i++) ...[
                HistoryCard(item: items[i], onTap: () => _openDetail(items[i])),
                if (i < items.length - 1)
                  const SizedBox(height: RoastmateSpacing.md),
              ],
            const SizedBox(height: RoastmateSpacing.xl),
            HistoryExportCard(onExport: _onExportCsv),
            const SizedBox(height: RoastmateSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Riwayat Analisis',
                style: RoastmateText.headlineSm.copyWith(
                  color: RoastmateColors.textPrimary,
                ),
              ),
              const SizedBox(height: RoastmateSpacing.xs),
              Text(
                'Total ${_allItems.length} penilaian batch optik tersimpan',
                style: RoastmateText.bodyMd.copyWith(
                  color: RoastmateColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: RoastmateSpacing.md),
        Material(
          color: RoastmateColors.surfaceContainer,
          borderRadius: BorderRadius.circular(RoastmateRadius.full),
          child: InkWell(
            onTap: _onExportCsv,
            borderRadius: BorderRadius.circular(RoastmateRadius.full),
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.download, color: RoastmateColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RoastmateSpacing.xl),
      decoration: BoxDecoration(
        color: RoastmateColors.surface,
        borderRadius: BorderRadius.circular(RoastmateRadius.large),
        border: Border.all(color: RoastmateColors.borderDefault),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 40,
            color: RoastmateColors.iconMuted,
          ),
          const SizedBox(height: RoastmateSpacing.md),
          Text(
            'Belum ada riwayat untuk filter ini',
            style: RoastmateText.titleSm.copyWith(
              color: RoastmateColors.textPrimary,
            ),
          ),
          const SizedBox(height: RoastmateSpacing.xs),
          Text(
            'Coba pilih filter lain atau scan batch baru.',
            textAlign: TextAlign.center,
            style: RoastmateText.bodySm.copyWith(
              color: RoastmateColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
