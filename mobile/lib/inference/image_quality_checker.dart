import 'dart:typed_data';

/// Hasil pengecekan kualitas gambar sebelum inferensi ML.
class ImageQualityResult {
  final bool isAcceptable;
  final String? rejectionReason;

  const ImageQualityResult.ok() : isAcceptable = true, rejectionReason = null;
  const ImageQualityResult.reject(String reason)
      : isAcceptable = false,
        rejectionReason = reason;
}

/// Exception bila kualitas gambar tidak memenuhi syarat.
class ImageQualityException implements Exception {
  final String reason;
  const ImageQualityException(this.reason);

  @override
  String toString() => 'ImageQualityException: $reason';
}

/// Memeriksa kualitas gambar: pencahayaan dan blur.
///
/// Menggunakan sampling pixel sederhana tanpa library eksternal,
/// sehingga kompatibel lintas platform (Android, iOS, unit test).
class ImageQualityChecker {
  /// Luminance minimum agar gambar dianggap cukup terang (0–255).
  static const double _minBrightness = 40.0;

  /// Varians Laplacian minimum agar gambar dianggap tidak buram.
  static const double _minSharpness = 50.0;

  /// Memeriksa kualitas gambar dari raw RGBA bytes.
  ///
  /// [bytes] adalah raw pixel RGBA, [width] × [height] pixel.
  /// Gunakan [checkFromBytes] untuk mengirim dari Isolate.
  ImageQualityResult checkFromBytes(
    Uint8List bytes,
    int width,
    int height,
  ) {
    if (bytes.isEmpty || width <= 0 || height <= 0) {
      return const ImageQualityResult.reject('Gambar tidak valid');
    }

    final brightness = _estimateBrightness(bytes, width, height);
    if (brightness < _minBrightness) {
      return const ImageQualityResult.reject(
        'Pencahayaan kurang — coba di tempat yang lebih terang',
      );
    }

    final sharpness = _estimateSharpness(bytes, width, height);
    if (sharpness < _minSharpness) {
      return const ImageQualityResult.reject(
        'Foto buram — tahan kamera lebih stabil',
      );
    }

    return const ImageQualityResult.ok();
  }

  /// Hitung rata-rata luminance dari sampel pixel.
  double _estimateBrightness(Uint8List bytes, int width, int height) {
    // Sample setiap 10 pixel untuk efisiensi
    const step = 10;
    double total = 0;
    int count = 0;

    for (int y = 0; y < height; y += step) {
      for (int x = 0; x < width; x += step) {
        final idx = (y * width + x) * 4; // RGBA
        if (idx + 2 >= bytes.length) continue;
        final r = bytes[idx];
        final g = bytes[idx + 1];
        final b = bytes[idx + 2];
        // ITU-R BT.601 luminance
        total += 0.299 * r + 0.587 * g + 0.114 * b;
        count++;
      }
    }

    return count > 0 ? total / count : 0;
  }

  /// Estimasi ketajaman gambar via varians Laplacian sederhana.
  double _estimateSharpness(Uint8List bytes, int width, int height) {
    if (width < 3 || height < 3) return 0;

    // Sample area tengah saja (lebih representatif untuk biji kopi)
    final startX = width ~/ 4;
    final endX = 3 * width ~/ 4;
    final startY = height ~/ 4;
    final endY = 3 * height ~/ 4;

    final values = <double>[];
    const step = 5;

    for (int y = startY + 1; y < endY - 1; y += step) {
      for (int x = startX + 1; x < endX - 1; x += step) {
        final center = _gray(bytes, x, y, width);
        final top = _gray(bytes, x, y - 1, width);
        final bottom = _gray(bytes, x, y + 1, width);
        final left = _gray(bytes, x - 1, y, width);
        final right = _gray(bytes, x + 1, y, width);
        // Laplacian kernel: -4*center + top + bottom + left + right
        final lap = -4 * center + top + bottom + left + right;
        values.add(lap.abs().toDouble());
      }
    }

    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    // Varians dari nilai absolut Laplacian sebagai proxy sharpness
    final variance = values
        .map((v) => (v - mean) * (v - mean))
        .reduce((a, b) => a + b) / values.length;
    return variance;
  }

  int _gray(Uint8List bytes, int x, int y, int width) {
    final idx = (y * width + x) * 4;
    if (idx + 2 >= bytes.length) return 0;
    final r = bytes[idx];
    final g = bytes[idx + 1];
    final b = bytes[idx + 2];
    return (0.299 * r + 0.587 * g + 0.114 * b).round();
  }
}

