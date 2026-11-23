/// API publik pipeline inference on-device.
///
/// Alur (`docs/ARCHITECTURE_MOBILE.md` §8):
/// foto → deteksi biji → crop → klasifikasi (species/roast/defect) →
/// agregasi batch. Inference berjalan di isolate terpisah; model dimuat satu
/// per satu lalu dibebaskan.
///
/// Shape Analysis masih interim (geometri bbox) — lihat
/// `batch_aggregation.dart`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'batch_aggregation.dart';
import 'inference_isolate.dart';
import 'model_asset_cache.dart';

/// Versi pipeline yang disimpan di `analyses.model_version`.
const String kModelVersion = 'ml-v1 (yolov8n-fp16 + mobilenetv3-fp32)';

/// Tidak ada biji yang terdeteksi pada foto.
class NoBeansDetectedException implements Exception {
  const NoBeansDetectedException();

  @override
  String toString() =>
      'Tidak ada biji kopi yang terdeteksi. Dekatkan kamera dan coba lagi.';
}

/// Foto gagal dianalisis (format rusak / model error).
class InferenceException implements Exception {
  const InferenceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Pipeline inference on-device.
class InferencePipeline {
  const InferencePipeline();

  /// Analisis satu foto dan kembalikan ringkasan batch.
  ///
  /// Melempar [NoBeansDetectedException] bila detektor tidak menemukan biji,
  /// [InferenceException] untuk kegagalan lain.
  Future<BatchSummary> analyze(String imagePath) async {
    final ModelPaths paths;
    try {
      paths = await ModelAssetCache.instance.ensure();
    } catch (e) {
      throw InferenceException('Model gagal disiapkan: $e');
    }

    final List<RawBeanData> beans;
    try {
      beans = await runInferenceInIsolate(
        imagePath: imagePath,
        detectorPath: paths.detector,
        speciesPath: paths.species,
        roastPath: paths.roast,
        defectPath: paths.defect,
      );
    } catch (e) {
      throw InferenceException('Analisis gagal: $e');
    }

    if (beans.isEmpty) throw const NoBeansDetectedException();

    return aggregateBatch(<BeanPrediction>[
      for (final bean in beans)
        BeanPrediction(
          x1: bean.box[0],
          y1: bean.box[1],
          x2: bean.box[2],
          y2: bean.box[3],
          detectConfidence: bean.detectConfidence,
          speciesProbs: bean.speciesProbs,
          roastProbs: bean.roastProbs,
          defectProbs: bean.defectProbs,
        ),
    ]);
  }
}

/// Provider pipeline (dapat di-override di test).
final inferencePipelineProvider = Provider<InferencePipeline>(
  (ref) => const InferencePipeline(),
);
