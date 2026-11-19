import 'package:flutter/material.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../../domain/entities/brew_recipe.dart';
import '../../domain/entities/brew_tool.dart';

/// Bagian "Persiapan & Alat Seduh" pada Detail Resep.
///
/// Berisi langkah ber-`phase` `prep` (D-18) serta relasi `tools`.
class PreparationList extends StatelessWidget {
  final List<BrewStep> steps;
  final List<BrewTool> tools;

  const PreparationList({
    super.key,
    required this.steps,
    this.tools = const [],
  });

  @override
  Widget build(BuildContext context) {
    final count = tools.isNotEmpty ? tools.length : steps.length;
    return Container(
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
            children: [
              const Icon(
                Icons.construction_outlined,
                size: 18,
                color: RoastmateColors.textSecondary,
              ),
              const SizedBox(width: RoastmateSpacing.sm),
              Expanded(
                child: Text(
                  'Persiapan & Alat Seduh',
                  style: RoastmateText.titleMd.copyWith(
                    color: RoastmateColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$count Alat Utama',
                style: RoastmateText.bodySm.copyWith(
                  color: RoastmateColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.md),
          if (tools.isNotEmpty)
            for (final tool in tools) _ToolItem(tool: tool)
          else
            for (final step in steps) _PreparationItem(step: step),
        ],
      ),
    );
  }
}

class _ToolItem extends StatelessWidget {
  final BrewTool tool;

  const _ToolItem({required this.tool});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: RoastmateSpacing.sm),
      padding: const EdgeInsets.all(RoastmateSpacing.md),
      decoration: BoxDecoration(
        color: RoastmateColors.surface,
        borderRadius: BorderRadius.circular(RoastmateRadius.small),
        border: Border.all(color: RoastmateColors.borderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: RoastmateColors.surfaceContainer,
              borderRadius: BorderRadius.circular(RoastmateRadius.small),
            ),
            clipBehavior: Clip.antiAlias,
            child: tool.imageAsset != null && tool.imageAsset!.isNotEmpty
                ? Image.asset(
                    tool.imageAsset!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.coffee_maker_outlined,
                      size: 20,
                      color: RoastmateColors.textSecondary,
                    ),
                  )
                : const Icon(
                    Icons.coffee_maker_outlined,
                    size: 20,
                    color: RoastmateColors.textSecondary,
                  ),
          ),
          const SizedBox(width: RoastmateSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tool.toolName,
                        style: RoastmateText.titleSm.copyWith(
                          color: RoastmateColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!tool.isRequired)
                      Text(
                        'Opsional',
                        style: RoastmateText.labelSm.copyWith(
                          color: RoastmateColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                if (tool.description != null && tool.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    tool.description!,
                    style: RoastmateText.bodySm.copyWith(
                      color: RoastmateColors.textSecondary,
                    ),
                  ),
                ],
                if (tool.notes != null && tool.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Catatan: ${tool.notes!}',
                    style: RoastmateText.bodySm.copyWith(
                      color: RoastmateColors.secondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: RoastmateSpacing.sm),
          const Icon(
            Icons.check_circle_outline,
            size: 20,
            color: RoastmateColors.tertiary,
          ),
        ],
      ),
    );
  }
}

class _PreparationItem extends StatelessWidget {
  final BrewStep step;

  const _PreparationItem({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: RoastmateSpacing.sm),
      padding: const EdgeInsets.all(RoastmateSpacing.md),
      decoration: BoxDecoration(
        color: RoastmateColors.surface,
        borderRadius: BorderRadius.circular(RoastmateRadius.small),
        border: Border.all(color: RoastmateColors.borderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: RoastmateText.titleSm.copyWith(
                    color: RoastmateColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.description,
                  style: RoastmateText.bodySm.copyWith(
                    color: RoastmateColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: RoastmateSpacing.sm),
          const Icon(
            Icons.check_circle_outline,
            size: 20,
            color: RoastmateColors.tertiary,
          ),
        ],
      ),
    );
  }
}
