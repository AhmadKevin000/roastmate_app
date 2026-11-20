import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../../../../core/widgets/roastmate_app_bar.dart';
import '../../domain/entities/brew_recipe.dart';
import '../viewmodels/brew_view_model.dart';
import '../widgets/brew_metric_tile.dart';
import '../widgets/brewing_step_list.dart';
import '../widgets/recipe_video_card.dart';
import '../widgets/tasting_notes_card.dart';

/// Layar "Detail Resep Kamu" — resep buatan user (v6).
///
/// Layout selaras Detail Resep KB: hero nama resep + metrik, langkah seduh
/// (bila ada), video brewing (bila ada), dan catatan.
/// Tersedia tombol Edit (AppBar) dan Hapus (bottom) untuk manajemen resep.
class UserRecipeDetailScreen extends ConsumerWidget {
  final String recipeId;

  const UserRecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRecipe = ref.watch(brewUserRecipeByIdProvider(recipeId));

    return Scaffold(
      backgroundColor: RoastmateColors.background,
      appBar: asyncRecipe.maybeWhen(
        data: (recipe) => recipe != null
            ? RoastmateAppBar(
                title: 'Detail Resep',
                actions: [
                  IconButton(
                    tooltip: 'Edit resep',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      context.push('/brewing/edit', extra: recipe);
                    },
                  ),
                ],
              )
            : const RoastmateAppBar(title: 'Detail Resep'),
        orElse: () => const RoastmateAppBar(title: 'Detail Resep'),
      ),
      body: asyncRecipe.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: RoastmateColors.primary),
        ),
        error: (e, _) =>
            _buildNotFound(context, message: 'Gagal memuat resep: $e'),
        data: (recipe) => recipe == null
            ? _buildNotFound(context)
            : _buildContent(context, ref, recipe),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context, {String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RoastmateSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: 32,
              color: RoastmateColors.iconMuted,
            ),
            const SizedBox(height: RoastmateSpacing.md),
            Text(
              message ?? 'Resep tidak ditemukan.',
              style: RoastmateText.bodyLg.copyWith(
                color: RoastmateColors.textPrimary,
              ),
            ),
            const SizedBox(height: RoastmateSpacing.lg),
            OutlinedButton(
              onPressed: () {
                if (context.canPop()) context.pop();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: RoastmateColors.primary,
                side: const BorderSide(color: RoastmateColors.borderDefault),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RoastmateRadius.small),
                ),
                minimumSize: const Size(0, 48),
              ),
              child: Text('Kembali', style: RoastmateText.labelLg),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    BrewRecipe recipe,
  ) {
    final chips = [
      _chip(
        recipe.methodName.isEmpty ? 'Metode Kustom' : recipe.methodName,
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
    ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: RoastmateText.titleLg.copyWith(
                          color: RoastmateColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: RoastmateSpacing.sm),
                      Wrap(
                        spacing: RoastmateSpacing.xs,
                        runSpacing: RoastmateSpacing.xs,
                        children: chips,
                      ),
                      const SizedBox(height: RoastmateSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: BrewMetricTile(
                              stacked: true,
                              label: 'Berat',
                              value: recipe.doseLabel,
                            ),
                          ),
                          const SizedBox(width: RoastmateSpacing.md),
                          Expanded(
                            child: BrewMetricTile(
                              stacked: true,
                              label: 'Total Air',
                              value: recipe.waterLabel,
                            ),
                          ),
                          const SizedBox(width: RoastmateSpacing.md),
                          Expanded(
                            child: BrewMetricTile(
                              stacked: true,
                              label: 'Suhu Air',
                              value: recipe.tempLabel,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: RoastmateSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: BrewMetricTile(
                              stacked: true,
                              label: 'Gilingan',
                              value: recipe.grindLabel,
                            ),
                          ),
                          const SizedBox(width: RoastmateSpacing.md),
                          Expanded(
                            child: BrewMetricTile(
                              stacked: true,
                              label: 'Total Waktu',
                              value: recipe.timeLabel,
                            ),
                          ),
                          const SizedBox(width: RoastmateSpacing.md),
                          Expanded(
                            child: BrewMetricTile(
                              stacked: true,
                              label: 'Rasio',
                              value: recipe.ratioLabel,
                            ),
                          ),
                        ],
                      ),
                      if (recipe.brewSteps.isNotEmpty) ...[
                        const SizedBox(height: RoastmateSpacing.xl),
                        BrewingStepList(steps: recipe.brewSteps),
                      ],
                      if (recipe.videoUrl != null &&
                          recipe.videoUrl!.isNotEmpty) ...[
                        const SizedBox(height: RoastmateSpacing.xl),
                        RecipeVideoCard(videoUrl: recipe.videoUrl!),
                      ],
                      const SizedBox(height: RoastmateSpacing.xl),
                      TastingNotesCard(intro: recipe.notes),
                      const SizedBox(height: RoastmateSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // ── Action bar bawah: Hapus ──────────────────────────────────────
        _buildActionBar(context, ref, recipe),
      ],
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    WidgetRef ref,
    BrewRecipe recipe,
  ) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RoastmateSpacing.lg,
          vertical: RoastmateSpacing.md,
        ),
        child: Row(
          children: [
            // Tombol Edit
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/brewing/edit', extra: recipe),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Resep'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: RoastmateColors.primary,
                  side: const BorderSide(color: RoastmateColors.primary),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(RoastmateRadius.small),
                  ),
                ),
              ),
            ),
            const SizedBox(width: RoastmateSpacing.sm),
            // Tombol Hapus
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, ref, recipe.recipeId),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Hapus'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: RoastmateColors.error,
                  side: const BorderSide(color: RoastmateColors.error),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(RoastmateRadius.small),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String recipeId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Resep?'),
        content: const Text(
          'Resep ini akan dihapus permanen dan tidak bisa dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: RoastmateColors.error,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(brewCatalogProvider.notifier).removeRecipe(recipeId);
      if (context.mounted) context.pop();
    }
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
}
