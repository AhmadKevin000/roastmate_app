import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_sem5/inference/batch_aggregation.dart';
import 'package:pbl_sem5/inference/inference_isolate.dart';

/// Smoke test sementara: jalankan pipeline nyata pada sample_batch.jpg.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pipeline nyata pada sample_batch.jpg', () async {
    final dir = Directory.systemTemp.createTempSync('roastmate_models');
    final paths = <String, String>{};
    for (final name in <String>[
      'bean_detection.tflite',
      'species_classifier.tflite',
      'roast_classifier.tflite',
      'defect_classifier.tflite',
    ]) {
      final data = await rootBundle.load('assets/models/$name');
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      paths[name] = file.path;
    }

    final stopwatch = Stopwatch()..start();
    List<dynamic> beans;
    try {
      beans = await runInferenceInIsolate(
        imagePath: 'assets/images/sample_batch.jpg',
        detectorPath: paths['bean_detection.tflite']!,
        speciesPath: paths['species_classifier.tflite']!,
        roastPath: paths['roast_classifier.tflite']!,
        defectPath: paths['defect_classifier.tflite']!,
      );
    } catch (e) {
      if (e.toString().contains('Failed to load dynamic library') ||
          e.toString().contains('libtensorflowlite_c')) {
        // ignore: avoid_print
        print('Skipping smoke test: native tensorflowlite_c library not available on this host: $e');
        return;
      }
      rethrow;
    }
    stopwatch.stop();

    // ignore: avoid_print
    print('durasi=${stopwatch.elapsedMilliseconds}ms beans=${beans.length}');

    final summary = aggregateBatch([
      for (final b in beans)
        BeanPrediction(
          x1: b.box[0],
          y1: b.box[1],
          x2: b.box[2],
          y2: b.box[3],
          detectConfidence: b.detectConfidence,
          speciesProbs: b.speciesProbs,
          roastProbs: b.roastProbs,
          defectProbs: b.defectProbs,
        ),
    ]);

    // ignore: avoid_print
    print(
      'species=${summary.species} (${summary.speciesConfidence.toStringAsFixed(3)}) '
      'roast=${summary.roast} (${summary.roastConfidence.toStringAsFixed(3)}) '
      'defects=${summary.defectCounts} rate=${summary.defectRate.toStringAsFixed(3)} '
      'shape=${summary.shapeUniformity.toStringAsFixed(3)} '
      'size=${summary.sizeUniformity.toStringAsFixed(3)}',
    );
    // ignore: avoid_print
    print(
      'contoh probs=${beans.first.speciesProbs} ${beans.first.roastProbs} ${beans.first.defectProbs}',
    );

    expect(beans, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
