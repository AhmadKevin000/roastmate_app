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
import '../widgets/brewing_step_list.dart';
import '../widgets/preparation_list.dart';
import '../widgets/recipe_summary_card.dart';
import '../widgets/tasting_notes_card.dart';

/// Layar "Detail Resep" — panduan langkah statis (FR-07).
///
/// Tidak ada timer interaktif (D-01); label waktu bersifat informatif.
class RecipeDetailScreen extends ConsumerWidget {
  final String methodId;

  const RecipeDetailScreen({super.key, required this.methodId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final method = ref.watch(brewMethodByIdProvider(methodId));
    final recipe = ref.watch(brewRecipeForMethodProvider(methodId));

    return Scaffold(
      backgroundColor: RoastmateColors.background,
      appBar: const RoastmateAppBar(title: 'Detail Resep'),
      body: method == null || recipe == null
          ? _buildNotFound(context)
          : _buildContent(method, recipe),
    );
  }

  Widget _buildNotFound(BuildContext context) {
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
              'Resep tidak ditemukan.',
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

  Widget _buildContent(BrewMethod method, BrewRecipe recipe) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RecipeSummaryCard(method: method, recipe: recipe),
                const SizedBox(height: RoastmateSpacing.xl),
                PreparationList(steps: recipe.prepSteps),
                const SizedBox(height: RoastmateSpacing.xl),
                BrewingStepList(steps: recipe.brewSteps),
                const SizedBox(height: RoastmateSpacing.xl),
                TastingNotesCard(intro: recipe.notes),
                const SizedBox(height: RoastmateSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
