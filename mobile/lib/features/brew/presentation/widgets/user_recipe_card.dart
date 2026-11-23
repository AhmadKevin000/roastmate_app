import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../../domain/entities/brew_recipe.dart';
import '../viewmodels/brew_view_model.dart';

/// Kartu resep buatan user di seksi "Resep Kamu".
///
/// Menampilkan nama, chip metode/species/roast, baris parameter (reuse label
/// [BrewRecipe]), notes satu baris, serta aksi edit dan hapus.
/// [onTap] membuka Detail Resep Kamu (v6).
class UserRecipeCard extends ConsumerWidget {
  const UserRecipeCard({
    super.key,
    required this.recipe,
    this.method,
    this.onTap,
    this.onEdit,
  });

  final BrewRecipe recipe;

  /// Metode KB yang dirujuk (untuk label nama); null bila tak ditemukan
  /// atau metode "Lainnya" (v6).
  final BrewMethod? method;

  /// Buka detail resep (v6).
  final VoidCallback? onTap;

  /// Aksi edit resep (opsional; default membuka `/brewing/edit` dengan data resep).
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = [
      recipe.ratioLabel,
      recipe.tempLabel,
      recipe.grindLabel,
      recipe.timeLabel,
    ].where((p) => p != '—').join(' · ');

    final notes = recipe.notes;

    return Material(
      color: RoastmateColors.surface,
      borderRadius: BorderRadius.circular(RoastmateRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RoastmateRadius.large),
        child: Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      style: RoastmateText.titleMd.copyWith(
                        color: RoastmateColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit resep',
                    onPressed: onEdit ??
                        () => context.push('/brewing/edit', extra: recipe),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: RoastmateColors.primary,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hapus resep',
                    onPressed: () => _confirmDelete(context, ref),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: RoastmateColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: RoastmateSpacing.sm),
              Wrap(
                spacing: RoastmateSpacing.xs,
                runSpacing: RoastmateSpacing.xs,
                children: [
                  _chip(
                    method?.methodName ?? recipe.methodName,
                    RoastmateColors.espressoSoft,
                    RoastmateColors.primary,
                  ),
                  _chip(
                    recipe.species,
                    RoastmateColors.statusInfoContainer,
                    RoastmateColors.statusInfo,
                  ),
                  _chip(
                    recipe.roastContext,
                    RoastmateColors.surfaceContainer,
                    RoastmateColors.textSecondary,
                  ),
                ],
              ),
              if (params.isNotEmpty) ...[
                const SizedBox(height: RoastmateSpacing.sm),
                Text(
                  params,
                  style: RoastmateText.bodySm.copyWith(
                    color: RoastmateColors.textSecondary,
                  ),
                ),
              ],
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: RoastmateSpacing.xs),
                Text(
                  notes,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RoastmateText.bodySm.copyWith(
                    color: RoastmateColors.iconMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RoastmateSpacing.sm,
        vertical: RoastmateSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(RoastmateRadius.full),
      ),
      child: Text(
        label,
        style: RoastmateText.labelSm.copyWith(color: foreground),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Resep?'),
        content: Text(
          'Resep "${recipe.name}" akan dihapus permanen. '
          'Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: RoastmateColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(brewCatalogProvider.notifier)
          .removeRecipe(recipe.recipeId);
    }
  }
}
