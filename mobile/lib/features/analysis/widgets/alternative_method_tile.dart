import 'package:flutter/material.dart';
import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_text.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_radius.dart';
import '../../../domain/inspection_result.dart';

class AlternativeMethodTile extends StatelessWidget {
  final AlternativeMethod method;

  const AlternativeMethodTile({Key? key, required this.method}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(RoastmateRadius.large)),
          ),
          builder: (context) {
            return Container(
              padding: const EdgeInsets.all(RoastmateSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.title, style: RoastmateText.titleLg),
                  const SizedBox(height: RoastmateSpacing.md),
                  Text(method.description, style: RoastmateText.bodyLg),
                  const SizedBox(height: RoastmateSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RoastmateColors.primary,
                        foregroundColor: RoastmateColors.surface,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RoastmateRadius.small)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text("Tutup", style: RoastmateText.labelLg),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
      borderRadius: BorderRadius.circular(RoastmateRadius.small),
      child: Container(
        padding: const EdgeInsets.all(RoastmateSpacing.md),
        decoration: BoxDecoration(
          color: RoastmateColors.terracottaSoft,
          borderRadius: BorderRadius.circular(RoastmateRadius.small),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.title,
                    style: RoastmateText.titleSm.copyWith(color: RoastmateColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.description,
                    style: RoastmateText.bodySm.copyWith(color: RoastmateColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: RoastmateColors.iconDefault, size: 20),
          ],
        ),
      ),
    );
  }
}
