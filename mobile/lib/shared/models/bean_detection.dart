import 'dart:ui';

import '../enums/defect_class.dart';

/// Satu deteksi biji pada bukti visual (overlay bounding box).
///
/// [normalizedRect] memakai koordinat ternormalisasi 0..1.
class BeanDetection {
  final DefectClass classLabel;
  final Rect normalizedRect; // 0..1
  final double confidence;

  BeanDetection({
    required this.classLabel,
    required this.normalizedRect,
    required this.confidence,
  });
}
