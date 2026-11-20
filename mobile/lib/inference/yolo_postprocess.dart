/// Post-processing detector YOLOv8n (pure Dart, bisa diuji tanpa model).
///
/// Output model `(1, 5, 8400)` = 4 koordinat `cx, cy, w, h` (piksel ruang
/// letterbox 640) + 1 skor. Decode → filter confidence → NMS → koordinat
/// ternormalisasi 0..1 pada gambar asli.
library;

/// Satu kotak deteksi.
class RawDetection {
  const RawDetection({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.confidence,
  });

  /// Koordinat piksel (ruang yang sama dengan input model).
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double confidence;

  double get width => x2 - x1;
  double get height => y2 - y1;
  double get area => (width < 0 ? 0 : width) * (height < 0 ? 0 : height);

  double get centerX => (x1 + x2) / 2;
  double get centerY => (y1 + y2) / 2;

  RawDetection copyWith({
    double? x1,
    double? y1,
    double? x2,
    double? y2,
    double? confidence,
  }) {
    return RawDetection(
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
      x2: x2 ?? this.x2,
      y2: y2 ?? this.y2,
      confidence: confidence ?? this.confidence,
    );
  }
}

/// Decode tensor YOLO menjadi kotak (belum NMS).
///
/// [output] panjang `5 * anchors` dengan layout channel-major
/// (`cx[0..n-1]`, `cy[0..n-1]`, `w[...]`, `h[...]`, `score[...]`).
List<RawDetection> decodeYoloOutput(
  List<double> output, {
  required int anchors,
  required double confidenceThreshold,
  int maxCandidates = 300,
}) {
  final detections = <RawDetection>[];
  for (var i = 0; i < anchors; i++) {
    final score = output[4 * anchors + i];
    if (score < confidenceThreshold) continue;

    final cx = output[i];
    final cy = output[anchors + i];
    final w = output[2 * anchors + i];
    final h = output[3 * anchors + i];

    detections.add(
      RawDetection(
        x1: cx - w / 2,
        y1: cy - h / 2,
        x2: cx + w / 2,
        y2: cy + h / 2,
        confidence: score,
      ),
    );
  }

  // Simpan kandidat terbaik saja agar NMS tidak meledak di RAM.
  if (detections.length > maxCandidates) {
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    return detections.sublist(0, maxCandidates);
  }
  return detections;
}

/// Intersection over Union dua kotak.
double iou(RawDetection a, RawDetection b) {
  final interX1 = a.x1 > b.x1 ? a.x1 : b.x1;
  final interY1 = a.y1 > b.y1 ? a.y1 : b.y1;
  final interX2 = a.x2 < b.x2 ? a.x2 : b.x2;
  final interY2 = a.y2 < b.y2 ? a.y2 : b.y2;

  final interW = interX2 - interX1;
  final interH = interY2 - interY1;
  if (interW <= 0 || interH <= 0) return 0;

  final intersection = interW * interH;
  final union = a.area + b.area - intersection;
  return union <= 0 ? 0 : intersection / union;
}

/// Non-maximum suppression (greedy, confidence desc).
List<RawDetection> nonMaxSuppression(
  List<RawDetection> detections, {
  double iouThreshold = 0.45,
  int maxDetections = 100,
}) {
  final sorted = List<RawDetection>.from(detections)
    ..sort((a, b) => b.confidence.compareTo(a.confidence));

  final kept = <RawDetection>[];
  for (final candidate in sorted) {
    if (kept.length >= maxDetections) break;
    var overlap = false;
    for (final selected in kept) {
      if (iou(candidate, selected) > iouThreshold) {
        overlap = true;
        break;
      }
    }
    if (!overlap) kept.add(candidate);
  }
  return kept;
}

/// Ubah kotak dari ruang letterbox (piksel) → ternormalisasi 0..1 gambar asli.
///
/// [scale] & [padX]/[padY] berasal dari operasi letterbox. Kotak yang keluar
/// frame di-clamp ke 0..1.
List<RawDetection> toOriginalNormalized(
  List<RawDetection> detections, {
  required double scale,
  required double padX,
  required double padY,
  required int imageWidth,
  required int imageHeight,
}) {
  if (scale <= 0) return const <RawDetection>[];

  double clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  return detections
      .map(
        (d) => RawDetection(
          x1: clamp01((d.x1 - padX) / scale / imageWidth),
          y1: clamp01((d.y1 - padY) / scale / imageHeight),
          x2: clamp01((d.x2 - padX) / scale / imageWidth),
          y2: clamp01((d.y2 - padY) / scale / imageHeight),
          confidence: d.confidence,
        ),
      )
      .where((d) => d.width > 0.01 && d.height > 0.01)
      .toList(growable: false);
}
