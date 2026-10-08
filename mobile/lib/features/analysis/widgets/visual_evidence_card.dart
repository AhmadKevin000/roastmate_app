import 'package:flutter/material.dart';
import '../../../core/roastmate_colors.dart';
import '../../../core/roastmate_text.dart';
import '../../../core/roastmate_spacing.dart';
import '../../../core/roastmate_radius.dart';
import '../../../domain/inspection_result.dart';
import 'bean_overlay_painter.dart';

class VisualEvidenceCard extends StatelessWidget {
  final InspectionResult result;

  const VisualEvidenceCard({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: RoastmateSpacing.lg),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.center_focus_strong_outlined, size: 16, color: RoastmateColors.textSecondary),
                  const SizedBox(width: RoastmateSpacing.sm),
                  Text(
                    "Bukti Visual Klasifikasi",
                    style: RoastmateText.labelSm.copyWith(color: RoastmateColors.textSecondary),
                  ),
                ],
              ),
              Text(
                result.modelVersion,
                style: RoastmateText.labelSm.copyWith(color: RoastmateColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(RoastmateRadius.small),
            child: AspectRatio(
              aspectRatio: 1.35,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/sample_batch.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: RoastmateColors.surfaceContainer,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, color: RoastmateColors.iconMuted),
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: BeanOverlayPainter(result.detections),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () {
                        _showFullScreenImage(context);
                      },
                      borderRadius: BorderRadius.circular(RoastmateRadius.full),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: RoastmateColors.surfaceInverse.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(RoastmateRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.zoom_in, size: 16, color: RoastmateColors.surface),
                            const SizedBox(width: 4),
                            Text("Ketuk perbesar", style: RoastmateText.labelSm.copyWith(color: RoastmateColors.surface)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: RoastmateSpacing.md),
          Wrap(
            spacing: RoastmateSpacing.sm,
            runSpacing: RoastmateSpacing.xs,
            children: _buildLegend(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLegend() {
    final Map<DefectClass, String> labels = {
      DefectClass.healthy: "Healthy",
      DefectClass.broken: "Broken",
      DefectClass.insectDamage: "Insect Damage",
      DefectClass.quaker: "Quaker",
      DefectClass.scorched: "Scorched",
      DefectClass.foreignMatter: "Foreign Matter",
    };

    return result.defectCounts.entries
        .where((e) => e.value > 0)
        .map((e) {
      final colorName = e.key.name == 'insectDamage' ? 'insect' : (e.key.name == 'foreignMatter' ? 'foreign' : e.key.name);
      final color = RoastmateColors.defect[colorName] ?? RoastmateColors.primary;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            "${labels[e.key]} (${e.value})",
            style: RoastmateText.labelSm.copyWith(color: RoastmateColors.textPrimary),
          ),
        ],
      );
    }).toList();
  }

  void _showFullScreenImage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: RoastmateColors.surfaceInverse,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: RoastmateColors.surface),
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 1,
            maxScale: 4,
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/sample_batch.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: RoastmateColors.iconMuted),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: BeanOverlayPainter(result.detections),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
