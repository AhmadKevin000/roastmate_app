import 'package:flutter/material.dart';
import '../../../core/roastmate_colors.dart';
import '../../../domain/inspection_result.dart';

class BeanOverlayPainter extends CustomPainter {
  final List<BeanDetection> detections;

  BeanOverlayPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    for (var det in detections) {
      final rect = Rect.fromLTWH(
        det.normalizedRect.left * size.width,
        det.normalizedRect.top * size.height,
        det.normalizedRect.width * size.width,
        det.normalizedRect.height * size.height,
      );

      final colorName = det.classLabel.name == 'insectDamage' ? 'insect' : (det.classLabel.name == 'foreignMatter' ? 'foreign' : det.classLabel.name);
      final color = RoastmateColors.defect[colorName] ?? RoastmateColors.primary;

      if (det.classLabel == DefectClass.healthy) {
        final paint = Paint()
          ..color = color.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawRect(rect, paint);
      } else {
        final boxPaint = Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, boxPaint);

        final strokePaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawRect(rect, strokePaint);

        final textPainter = TextPainter(
          text: TextSpan(
            text: _getLabelName(det.classLabel),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final labelBgPaint = Paint()..color = color;
        final labelRect = Rect.fromLTWH(
          rect.left,
          rect.bottom,
          textPainter.width + 4,
          textPainter.height + 4,
        );
        canvas.drawRect(labelRect, labelBgPaint);

        textPainter.paint(canvas, Offset(rect.left + 2, rect.bottom + 2));
      }
    }
  }

  String _getLabelName(DefectClass c) {
    switch (c) {
      case DefectClass.healthy: return "Healthy";
      case DefectClass.broken: return "Broken";
      case DefectClass.insectDamage: return "Insect";
      case DefectClass.quaker: return "Quaker";
      case DefectClass.scorched: return "Scorched";
      case DefectClass.foreignMatter: return "Foreign";
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
