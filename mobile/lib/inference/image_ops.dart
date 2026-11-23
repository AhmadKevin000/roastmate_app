/// Operasi gambar untuk pipeline inference (pure Dart, `package:image`).
///
/// Kontrak preprocessing (`docs/ARCHITECTURE_ML.md` §4):
/// - Detector: letterbox 640×640, **RGB, 0..1** (YOLO).
/// - Classifier: crop + margin 10% → resize **224 bilinear**, **RGB, 0..255**
///   (normalisasi ImageNet ada di dalam model — jangan dinormalisasi di sini).
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Nilai padding letterbox (abu-abu YOLO standar).
const int kLetterboxPadValue = 114;

/// Hasil letterbox: gambar persegi + transformasi balik ke koordinat asli.
class LetterboxResult {
  const LetterboxResult({
    required this.image,
    required this.scale,
    required this.padX,
    required this.padY,
  });

  final img.Image image;
  final double scale;
  final double padX;
  final double padY;
}

/// Letterbox [src] ke kanvas persegi [size] tanpa mengubah rasio aspek.
LetterboxResult letterbox(img.Image src, {int size = 640}) {
  final scale = _min(size / src.width, size / src.height);
  final newWidth = (src.width * scale).round().clamp(1, size);
  final newHeight = (src.height * scale).round().clamp(1, size);
  final padX = ((size - newWidth) / 2).round();
  final padY = ((size - newHeight) / 2).round();

  final canvas = img.Image(width: size, height: size, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(114, 114, 114));
  final resized = img.copyResize(
    src,
    width: newWidth,
    height: newHeight,
    interpolation: img.Interpolation.linear,
  );
  img.compositeImage(canvas, resized, dstX: padX, dstY: padY);

  return LetterboxResult(
    image: canvas,
    scale: scale,
    padX: padX.toDouble(),
    padY: padY.toDouble(),
  );
}

/// Tensor input detector: NHWC, RGB, rentang **0..1**.
Float32List toDetectorInput(img.Image image) {
  final bytes = image.getBytes(order: img.ChannelOrder.rgb);
  final out = Float32List(bytes.length);
  for (var i = 0; i < bytes.length; i++) {
    out[i] = bytes[i] / 255.0;
  }
  return out;
}

/// Tensor input classifier: NHWC, RGB, rentang **0..255** (tanpa normalisasi).
Float32List toClassifierInput(img.Image image) {
  final bytes = image.getBytes(order: img.ChannelOrder.rgb);
  final out = Float32List(bytes.length);
  for (var i = 0; i < bytes.length; i++) {
    out[i] = bytes[i].toDouble();
  }
  return out;
}

/// Crop kotak ternormalisasi (0..1) dengan margin relatif, lalu resize ke
/// [outputSize] bilinear. Kotak di-clamp ke batas gambar.
img.Image cropNormalized(
  img.Image src,
  double x1,
  double y1,
  double x2,
  double y2, {
  double margin = 0.10,
  int outputSize = 224,
}) {
  final boxW = (x2 - x1).clamp(0.0, 1.0) * src.width;
  final boxH = (y2 - y1).clamp(0.0, 1.0) * src.height;
  final padX = boxW * margin;
  final padY = boxH * margin;

  var left = (x1 * src.width - padX).round();
  var top = (y1 * src.height - padY).round();
  var right = (x2 * src.width + padX).round();
  var bottom = (y2 * src.height + padY).round();

  left = left.clamp(0, src.width - 1);
  top = top.clamp(0, src.height - 1);
  right = right.clamp(left + 1, src.width);
  bottom = bottom.clamp(top + 1, src.height);

  final cropped = img.copyCrop(
    src,
    x: left,
    y: top,
    width: right - left,
    height: bottom - top,
  );

  return img.copyResize(
    cropped,
    width: outputSize,
    height: outputSize,
    interpolation: img.Interpolation.linear,
  );
}

double _min(double a, double b) => a < b ? a : b;
