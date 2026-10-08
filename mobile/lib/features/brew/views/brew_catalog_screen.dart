import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_radius.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_text.dart';
import '../viewmodels/brew_vm.dart';
import '../widgets/brew_method_card.dart';
import '../widgets/brewing_tip_card.dart';
import 'recipe_detail_screen.dart';

/// Layar "Resep Seduh" — katalog metode seduh (FR-06).
class BrewCatalogScreen extends ConsumerWidget {
  const BrewCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(brewCatalogProvider);

    return Scaffold(
      backgroundColor: RoastmateColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrewHeader(),
              const SizedBox(height: RoastmateSpacing.xl),
              _buildTitleRow(context, state),
              const SizedBox(height: RoastmateSpacing.lg),
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: RoastmateSpacing.xl),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: RoastmateColors.primary,
                    ),
                  ),
                )
              else if (state.isEmpty)
                _buildEmpty(context)
              else
                for (final method in state.methods)
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: RoastmateSpacing.lg),
                    child: BrewMethodCard(
                      method: method,
                      recipe: state.recipeForMethod(method.methodId),
                      onStartSetup: () => _openDetail(context, method.methodId),
                    ),
                  ),
              const SizedBox(height: RoastmateSpacing.sm),
              const BrewingTipCard(),
              const SizedBox(height: RoastmateSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, String methodId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeDetailScreen(methodId: methodId),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context, BrewCatalogState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Katalog Metode Seduh',
                style: RoastmateText.titleLg.copyWith(
                  color: RoastmateColors.textPrimary,
                ),
              ),
              const SizedBox(height: RoastmateSpacing.xs),
              Text(
                '${state.methods.length} Metode Inti Tersedia',
                style: RoastmateText.bodySm.copyWith(
                  color: RoastmateColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: RoastmateSpacing.md),
        InkWell(
          borderRadius: BorderRadius.circular(RoastmateRadius.full),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kustomisasi akan tersedia di versi berikutnya'),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: RoastmateSpacing.md,
              vertical: RoastmateSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: RoastmateColors.surfaceContainer,
              borderRadius: BorderRadius.circular(RoastmateRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.tune,
                  size: 16,
                  color: RoastmateColors.textSecondary,
                ),
                const SizedBox(width: RoastmateSpacing.xs),
                Text(
                  'Kustomisasi',
                  style: RoastmateText.labelMd.copyWith(
                    color: RoastmateColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
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
            Icons.coffee_outlined,
            size: 32,
            color: RoastmateColors.iconMuted,
          ),
          const SizedBox(height: RoastmateSpacing.md),
          Text(
            'Belum ada metode seduh tersedia.',
            style: RoastmateText.bodyLg.copyWith(
              color: RoastmateColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrewHeader extends StatelessWidget {
  const _BrewHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(RoastmateRadius.small),
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
            ),
            const SizedBox(width: RoastmateSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Roastmate',
                  style: RoastmateText.titleMd.copyWith(
                    color: RoastmateColors.primary,
                  ),
                ),
                Text(
                  'Seduh',
                  style: RoastmateText.bodySm.copyWith(
                    color: RoastmateColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                color: RoastmateColors.primary,
              ),
              onPressed: () {},
            ),
            const SizedBox(width: RoastmateSpacing.xs),
            const CircleAvatar(
              backgroundColor: RoastmateColors.primary,
              radius: 16,
              child: Icon(
                Icons.person,
                size: 20,
                color: RoastmateColors.surface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
