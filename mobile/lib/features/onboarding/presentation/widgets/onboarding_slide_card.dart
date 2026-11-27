import 'package:flutter/material.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../../domain/entities/onboarding_slide.dart';
import 'onboarding_visual_showcase.dart';

/// Card presentasi untuk setiap slide onboarding.
///
/// Mengikuti arsitektur Warm Technical Minimalism dengan layout:
/// - Visual Mockup Showcase (atas)
/// - Category Pill / Badge
/// - Title & Detailed Description
/// - Feature Highlights Checklist Chips
class OnboardingSlideCard extends StatelessWidget {
  final OnboardingSlide slide;

  const OnboardingSlideCard({super.key, required this.slide});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: RoastmateSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: RoastmateSpacing.sm),
          // 1. Visual Showcase
          OnboardingVisualShowcase(type: slide.type),
          const SizedBox(height: RoastmateSpacing.lg),

          // 2. Category Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: slide.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(RoastmateRadius.full),
              border: Border.all(
                color: slide.accentColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(slide.icon, size: 14, color: slide.accentColor),
                const SizedBox(width: 6),
                Text(
                  slide.categoryBadge,
                  style: RoastmateText.labelSm.copyWith(
                    color: slide.accentColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: RoastmateSpacing.sm),

          // 3. Title
          Text(
            slide.title,
            style: RoastmateText.titleLg.copyWith(
              color: RoastmateColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: RoastmateSpacing.xs),

          // 4. Description
          Text(
            slide.description,
            style: RoastmateText.bodyMd.copyWith(
              color: RoastmateColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: RoastmateSpacing.md),

          // 5. Highlights Chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(RoastmateSpacing.md),
            decoration: BoxDecoration(
              color: RoastmateColors.surface,
              borderRadius: BorderRadius.circular(RoastmateRadius.medium),
              border: Border.all(color: RoastmateColors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FITUR UTAMA',
                  style: RoastmateText.labelSm.copyWith(
                    color: RoastmateColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: RoastmateSpacing.xs),
                ...slide.highlights.map(
                  (hl) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 15,
                            color: slide.accentColor,
                          ),
                        ),
                        const SizedBox(width: RoastmateSpacing.sm),
                        Expanded(
                          child: Text(
                            hl,
                            style: RoastmateText.bodySm.copyWith(
                              color: RoastmateColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: RoastmateSpacing.lg),
        ],
      ),
    );
  }
}
