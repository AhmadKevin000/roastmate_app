import 'package:flutter/material.dart';
import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_text.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_radius.dart';

/// Baris chip filter species (Semua / Arabica / Robusta) untuk daftar riwayat.
class HistoryFilterBar extends StatelessWidget {
  /// Label filter berurutan, mis. `['Semua', 'Arabica', 'Robusta']`.
  final List<String> options;

  /// Filter yang sedang aktif.
  final String selected;

  /// Jumlah item per filter, dipakai sebagai angka di dalam chip.
  final Map<String, int> counts;

  final ValueChanged<String> onSelected;

  const HistoryFilterBar({
    Key? key,
    required this.options,
    required this.selected,
    required this.counts,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options) ...[
            _buildChip(option, option == selected),
            const SizedBox(width: RoastmateSpacing.sm),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool active) {
    final background = active ? RoastmateColors.primary : RoastmateColors.surfaceContainer;
    final foreground = active ? RoastmateColors.surface : RoastmateColors.textPrimary;
    final count = counts[label] ?? 0;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(RoastmateRadius.full),
      child: InkWell(
        onTap: () => onSelected(label),
        borderRadius: BorderRadius.circular(RoastmateRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RoastmateRadius.full),
            border: Border.all(
              color: active ? RoastmateColors.primary : RoastmateColors.borderDefault,
            ),
          ),
          child: Text(
            '$label ($count)',
            style: RoastmateText.labelMd.copyWith(
              color: foreground,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
