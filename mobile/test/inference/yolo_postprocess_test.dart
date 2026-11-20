import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_sem5/inference/yolo_postprocess.dart';

/// Bangun tensor YOLO channel-major: cx, cy, w, h, score.
List<double> _buildOutput({
  required int anchors,
  required List<List<double>> boxes, // [cx, cy, w, h, score]
}) {
  final out = List<double>.filled(anchors * 5, 0);
  for (var i = 0; i < boxes.length; i++) {
    out[i] = boxes[i][0];
    out[anchors + i] = boxes[i][1];
    out[2 * anchors + i] = boxes[i][2];
    out[3 * anchors + i] = boxes[i][3];
    out[4 * anchors + i] = boxes[i][4];
  }
  return out;
}

void main() {
  group('decodeYoloOutput', () {
    test('membuang kandidat di bawah ambang confidence', () {
      final out = _buildOutput(
        anchors: 3,
        boxes: [
          [100, 100, 20, 20, 0.9],
          [200, 200, 20, 20, 0.10],
          [300, 300, 20, 20, 0.55],
        ],
      );

      final result = decodeYoloOutput(
        out,
        anchors: 3,
        confidenceThreshold: 0.3,
      );

      expect(result, hasLength(2));
      expect(result.map((d) => d.confidence), containsAll([0.9, 0.55]));
    });

    test('mengubah cx/cy/w/h menjadi sudut kotak', () {
      final out = _buildOutput(
        anchors: 1,
        boxes: [
          [100, 50, 20, 40, 0.8],
        ],
      );

      final box = decodeYoloOutput(
        out,
        anchors: 1,
        confidenceThreshold: 0.3,
      ).single;

      expect(box.x1, 90);
      expect(box.y1, 30);
      expect(box.x2, 110);
      expect(box.y2, 70);
    });

    test('membatasi jumlah kandidat sesuai maxCandidates', () {
      final out = _buildOutput(
        anchors: 5,
        boxes: [
          for (var i = 0; i < 5; i++) [10.0 * i, 10.0, 5.0, 5.0, 0.9 - i * 0.1],
        ],
      );

      final result = decodeYoloOutput(
        out,
        anchors: 5,
        confidenceThreshold: 0.1,
        maxCandidates: 2,
      );

      expect(result, hasLength(2));
      expect(result.first.confidence, closeTo(0.9, 1e-9));
    });
  });

  group('nonMaxSuppression', () {
    test('menyisakan satu kotak untuk deteksi yang saling tumpang tindih', () {
      final detections = [
        const RawDetection(x1: 10, y1: 10, x2: 50, y2: 50, confidence: 0.9),
        const RawDetection(x1: 12, y1: 12, x2: 52, y2: 52, confidence: 0.8),
      ];

      final kept = nonMaxSuppression(detections, iouThreshold: 0.45);

      expect(kept, hasLength(1));
      expect(kept.single.confidence, 0.9);
    });

    test('mempertahankan kotak yang tidak tumpang tindih', () {
      final detections = [
        const RawDetection(x1: 0, y1: 0, x2: 20, y2: 20, confidence: 0.9),
        const RawDetection(x1: 100, y1: 100, x2: 120, y2: 120, confidence: 0.8),
      ];

      expect(nonMaxSuppression(detections), hasLength(2));
    });

    test('menghormati batas maxDetections', () {
      final detections = [
        for (var i = 0; i < 5; i++)
          RawDetection(
            x1: 100.0 * i,
            y1: 0,
            x2: 100.0 * i + 10,
            y2: 10,
            confidence: 0.9 - i * 0.1,
          ),
      ];

      expect(nonMaxSuppression(detections, maxDetections: 3), hasLength(3));
    });
  });

  group('toOriginalNormalized', () {
    test('membalik letterbox: skala & padding dikurangi', () {
      // Gambar 200×100 → letterbox 640: scale 3.2, padX 0, padY 160.
      final detections = [
        const RawDetection(x1: 0, y1: 160, x2: 640, y2: 480, confidence: 0.9),
      ];

      final result = toOriginalNormalized(
        detections,
        scale: 3.2,
        padX: 0,
        padY: 160,
        imageWidth: 200,
        imageHeight: 100,
      );

      expect(result.single.x1, 0);
      expect(result.single.y1, 0);
      expect(result.single.x2, closeTo(1, 1e-9));
      expect(result.single.y2, closeTo(1, 1e-9));
    });

    test('membuang kotak yang nyaris tanpa luas', () {
      final detections = [
        const RawDetection(x1: 10, y1: 10, x2: 11, y2: 11, confidence: 0.9),
      ];

      expect(
        toOriginalNormalized(
          detections,
          scale: 1,
          padX: 0,
          padY: 0,
          imageWidth: 640,
          imageHeight: 640,
        ),
        isEmpty,
      );
    });
  });
}
