import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pbl_sem5/inference/image_ops.dart';

img.Image _solid(int width, int height, {int r = 10, int g = 20, int b = 30}) {
  final image = img.Image(width: width, height: height, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(r, g, b));
  return image;
}

void main() {
  group('letterbox', () {
    test('gambar lanskap: lebar penuh, padding vertikal', () {
      final result = letterbox(_solid(200, 100), size: 640);

      expect(result.image.width, 640);
      expect(result.image.height, 640);
      expect(result.scale, closeTo(3.2, 1e-9));
      expect(result.padX, 0);
      expect(result.padY, 160);
    });

    test('gambar persegi: tanpa padding', () {
      final result = letterbox(_solid(500, 500), size: 640);

      expect(result.scale, closeTo(1.28, 1e-9));
      expect(result.padX, 0);
      expect(result.padY, 0);
    });

    test('gambar potret: padding horizontal', () {
      final result = letterbox(_solid(100, 200), size: 640);

      expect(result.padX, 160);
      expect(result.padY, 0);
    });
  });

  group('tensor input', () {
    test('detector: RGB 0..1', () {
      final input = toDetectorInput(_solid(2, 2, r: 255, g: 0, b: 51));

      expect(input, hasLength(2 * 2 * 3));
      expect(input[0], closeTo(1.0, 1e-6));
      expect(input[1], closeTo(0.0, 1e-6));
      expect(input[2], closeTo(0.2, 1e-6));
    });

    test('classifier: RGB 0..255 tanpa normalisasi', () {
      final input = toClassifierInput(_solid(2, 2, r: 255, g: 0, b: 51));

      expect(input[0], 255);
      expect(input[1], 0);
      expect(input[2], closeTo(51, 1e-6));
    });
  });

  group('cropNormalized', () {
    test('menghasilkan kotak 224×224 dari kotak ternormalisasi', () {
      final crop = cropNormalized(_solid(400, 400), 0.25, 0.25, 0.75, 0.75);

      expect(crop.width, 224);
      expect(crop.height, 224);
    });

    test('kotak di luar frame tetap di-clamp, tidak crash', () {
      final crop = cropNormalized(_solid(100, 100), -0.5, -0.5, 1.5, 1.5);

      expect(crop.width, 224);
      expect(crop.height, 224);
    });

    test('kotak sangat kecil tetap menghasilkan output valid', () {
      final crop = cropNormalized(_solid(640, 640), 0.5, 0.5, 0.5001, 0.5001);

      expect(crop.width, 224);
      expect(crop.height, 224);
    });
  });
}
