/// Cache model TFLite di filesystem agar bisa dibaca dari background isolate.
///
/// Asset Flutter tidak bisa diakses langsung dari isolate non-UI (tidak ada
/// `rootBundle`), sementara inference harus jalan di isolate. Solusi: salin
/// asset ke direktori aplikasi **sekali** (dengan cek ukuran), lalu isolate
/// membaca file biasa. Ini juga menjaga RAM tetap rendah karena interpreter
/// memuat model langsung dari file.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Nama file model kanonik (`docs/ARCHITECTURE_MOBILE.md` §7).
class ModelPaths {
  const ModelPaths({
    required this.detector,
    required this.species,
    required this.roast,
    required this.defect,
  });

  final String detector;
  final String species;
  final String roast;
  final String defect;
}

/// Penyalin asset model → file lokal (idempoten).
class ModelAssetCache {
  ModelAssetCache._();

  static final ModelAssetCache instance = ModelAssetCache._();

  /// Nama asset di `pubspec.yaml`.
  static const Map<String, String> assets = <String, String>{
    'bean_detection.tflite': 'assets/models/bean_detection.tflite',
    'species_classifier.tflite': 'assets/models/species_classifier.tflite',
    'roast_classifier.tflite': 'assets/models/roast_classifier.tflite',
    'defect_classifier.tflite': 'assets/models/defect_classifier.tflite',
  };

  ModelPaths? _cached;

  /// Pastikan keempat model tersedia sebagai file; kembalikan path-nya.
  Future<ModelPaths> ensure() async {
    final cached = _cached;
    if (cached != null) return cached;

    final dir = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'models'),
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final paths = <String, String>{};
    for (final entry in assets.entries) {
      final target = File(p.join(dir.path, entry.key));
      final data = await rootBundle.load(entry.value);
      final expected = data.lengthInBytes;

      final needsCopy =
          !await target.exists() || await target.length() != expected;
      if (needsCopy) {
        debugPrint('[ModelCache] Menyalin ${entry.key} ($expected bytes)…');
        await target.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
      }
      paths[entry.key] = target.path;
    }

    final result = ModelPaths(
      detector: paths['bean_detection.tflite']!,
      species: paths['species_classifier.tflite']!,
      roast: paths['roast_classifier.tflite']!,
      defect: paths['defect_classifier.tflite']!,
    );
    _cached = result;
    return result;
  }
}
