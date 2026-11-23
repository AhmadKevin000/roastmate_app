/// Pipeline inference yang berjalan di **background isolate**.
///
/// Model dimuat satu per satu dari file lalu ditutup sebelum model berikutnya
/// (menekan puncak RAM, `ARCHITECTURE_MOBILE.md` §8). Semua parameter masuk
/// dan hasil keluar berupa Map/List primitif agar aman dikirim antar isolate.
library;

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'image_ops.dart';
import 'yolo_postprocess.dart';

/// Batas jumlah biji yang diklasifikasi (jaga latensi & RAM).
const int kMaxBeans = 60;

/// Ambang default detector (mengikuti training: conf 0.30 / iou 0.45).
const double kDetectorConfidence = 0.30;
const double kDetectorIou = 0.45;

/// Hasil mentah satu biji (Map agar aman lintas isolate).
class RawBeanData {
  const RawBeanData({
    required this.box,
    required this.detectConfidence,
    required this.speciesProbs,
    required this.roastProbs,
    required this.defectProbs,
  });

  final List<double> box; // [x1,y1,x2,y2] ternormalisasi
  final double detectConfidence;
  final List<double> speciesProbs;
  final List<double> roastProbs;
  final List<double> defectProbs;
}

/// Jalankan pipeline penuh di isolate terpisah.
///
/// Mengembalikan daftar [RawBeanData] (kosong bila tidak ada biji terdeteksi).
Future<List<RawBeanData>> runInferenceInIsolate({
  required String imagePath,
  required String detectorPath,
  required String speciesPath,
  required String roastPath,
  required String defectPath,
}) {
  return Isolate.run(
    () => _runPipeline(
      imagePath: imagePath,
      detectorPath: detectorPath,
      speciesPath: speciesPath,
      roastPath: roastPath,
      defectPath: defectPath,
    ),
  );
}

Future<List<RawBeanData>> _runPipeline({
  required String imagePath,
  required String detectorPath,
  required String speciesPath,
  required String roastPath,
  required String defectPath,
}) async {
  final decoded = img.decodeImage(await File(imagePath).readAsBytes());
  if (decoded == null) {
    throw const FormatException('Foto tidak bisa dibaca.');
  }
  final source = decoded.numChannels == 3
      ? decoded
      : decoded.convert(numChannels: 3);

  // ---- 1) Detector ----
  final boxes = _detect(
    source,
    detectorPath,
    confidenceThreshold: kDetectorConfidence,
    iouThreshold: kDetectorIou,
  );
  if (boxes.isEmpty) return const <RawBeanData>[];

  final limited = boxes.length > kMaxBeans
      ? boxes.sublist(0, kMaxBeans)
      : boxes;

  // ---- 2) Tiga classifier, satu model pada satu waktu ----
  final speciesProbs = _classifyAll(source, limited, speciesPath);
  final roastProbs = _classifyAll(source, limited, roastPath);
  final defectProbs = _classifyAll(source, limited, defectPath);

  return <RawBeanData>[
    for (var i = 0; i < limited.length; i++)
      RawBeanData(
        box: <double>[
          limited[i].x1,
          limited[i].y1,
          limited[i].x2,
          limited[i].y2,
        ],
        detectConfidence: limited[i].confidence,
        speciesProbs: speciesProbs[i],
        roastProbs: roastProbs[i],
        defectProbs: defectProbs[i],
      ),
  ];
}

List<RawDetection> _detect(
  img.Image source,
  String modelPath, {
  required double confidenceThreshold,
  required double iouThreshold,
}) {
  final box = letterbox(source, size: 640);
  final input = toDetectorInput(box.image);

  final interpreter = Interpreter.fromFile(
    File(modelPath),
    options: InterpreterOptions()..threads = 2,
  );
  try {
    final outputTensor = interpreter.getOutputTensor(0);
    final shape = outputTensor.shape; // [1, 5, 8400]
    final anchors = shape[2];
    final channels = shape[1];

    final outBytes = Uint8List(outputTensor.numBytes());
    interpreter.run(input.buffer, outBytes.buffer);
    final raw = outBytes.buffer.asFloat32List();

    final candidates = decodeYoloOutput(
      raw,
      anchors: anchors,
      confidenceThreshold: confidenceThreshold,
    );
    final kept = nonMaxSuppression(
      candidates,
      iouThreshold: iouThreshold,
      maxDetections: kMaxBeans,
    );

    // `channels` dipakai hanya untuk sanity check layout (5 = xywh+score).
    assert(channels >= 5, 'Layout output detector tak terduga: $shape');

    return toOriginalNormalized(
      kept,
      scale: box.scale,
      padX: box.padX,
      padY: box.padY,
      imageWidth: source.width,
      imageHeight: source.height,
    );
  } finally {
    interpreter.close();
  }
}

/// Klasifikasi semua kotak dengan satu model (dimuat sekali, lalu ditutup).
List<List<double>> _classifyAll(
  img.Image source,
  List<RawDetection> boxes,
  String modelPath,
) {
  final interpreter = Interpreter.fromFile(
    File(modelPath),
    options: InterpreterOptions()..threads = 2,
  );
  try {
    final outputTensor = interpreter.getOutputTensor(0);
    final classCount = outputTensor.shape.last;
    final outBytes = Uint8List(outputTensor.numBytes());

    final results = <List<double>>[];
    for (final box in boxes) {
      final crop = cropNormalized(source, box.x1, box.y1, box.x2, box.y2);
      final input = toClassifierInput(crop);
      interpreter.run(input.buffer, outBytes.buffer);
      final probs = outBytes.buffer.asFloat32List();
      results.add(List<double>.from(probs.take(classCount)));
    }
    return results;
  } finally {
    interpreter.close();
  }
}
