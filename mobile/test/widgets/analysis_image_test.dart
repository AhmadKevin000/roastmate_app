// Uji `AnalysisImage` (Plan 3 §3): helper transformasi Cloudinary (pure)
// dan perilaku widget — URL / path lokal / placeholder / error.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/core/widgets/analysis_image.dart';

/// PNG 1×1 valid (agar decode lokal sukses tanpa errorBuilder).
final List<int> _kPng1x1 = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwACh'
  'wGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  group('cloudinaryThumbnailUrl', () {
    test('URL Cloudinary valid → transformasi c_fill di posisi benar', () {
      expect(
        cloudinaryThumbnailUrl(
          'https://res.cloudinary.com/demo/image/upload/batch_1.jpg',
        ),
        'https://res.cloudinary.com/demo/image/upload/'
        'c_fill,w_200,h_200/batch_1.jpg',
      );
    });

    test('lebar/tinggi custom dipakai', () {
      expect(
        cloudinaryThumbnailUrl(
          'https://res.cloudinary.com/acme/image/upload/x.png',
          width: 100,
          height: 80,
        ),
        'https://res.cloudinary.com/acme/image/upload/c_fill,w_100,h_80/x.png',
      );
    });

    test('URL non-Cloudinary → null (render apa adanya)', () {
      expect(cloudinaryThumbnailUrl('https://example.com/image/a.jpg'), isNull);
    });

    test('path lokal → null', () {
      expect(cloudinaryThumbnailUrl('/tmp/capture_123.jpg'), isNull);
    });
  });

  group('AnalysisImage', () {
    testWidgets('path null/kosong → placeholder ikon kopi, tanpa Image', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                AnalysisImage(imagePath: null),
                AnalysisImage(imagePath: '   '),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.coffee_outlined), findsNWidgets(2));
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('URL → NetworkImage; thumbnail memakai transformasi', (
      tester,
    ) async {
      const url = 'https://res.cloudinary.com/demo/image/upload/batch_1.jpg';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AnalysisImage(imagePath: url),
                AnalysisImage(imagePath: url, thumbnail: true),
              ],
            ),
          ),
        ),
      );
      // Cek provider tanpa menunggu jaringan (test env tak punya network).

      final images = find.byType(Image)
          .evaluate()
          .map((e) => e.widget as Image)
          .toList();
      expect(images, hasLength(2));
      expect((images[0].image as NetworkImage).url.toString(), url);
      expect(
        (images[1].image as NetworkImage).url.toString(),
        'https://res.cloudinary.com/demo/image/upload/'
        'c_fill,w_200,h_200/batch_1.jpg',
      );
    });

    testWidgets('URL non-Cloudinary → tampil apa adanya (tanpa transformasi)', (
      tester,
    ) async {
      const url = 'https://example.com/image/a.jpg';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AnalysisImage(imagePath: url, thumbnail: true)),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as NetworkImage).url.toString(), url);
    });

    testWidgets('path lokal valid → FileImage', (tester) async {
      final file = File(
        '${Directory.systemTemp.path}/roastmate_analysis_image_test.png',
      )..writeAsBytesSync(_kPng1x1);
      addTearDown(() => file.delete().ignore());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalysisImage(imagePath: file.path, thumbnail: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      final fileImage = image.image as FileImage;
      expect(fileImage.file.path, file.path);
      // PNG valid: decode sukses, placeholder tidak muncul.
      expect(find.byIcon(Icons.coffee_outlined), findsNothing);
    });

    testWidgets('path lokal hilang → placeholder, tanpa crash', (tester) async {
      // Error baca file dart:io adalah async *real* (di luar fake-async),
      // jadi harus diberi waktu nyata lewat runAsync agar errorBuilder jalan.
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnalysisImage(imagePath: '/tmp/tidak_ada_roastmate.png'),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      expect(find.byIcon(Icons.coffee_outlined), findsOneWidget);
    });

    testWidgets('URL gagal dimuat → placeholder, tanpa crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalysisImage(
              imagePath:
                  'https://res.cloudinary.com/demo/image/upload/hilang.jpg',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.coffee_outlined), findsOneWidget);
    });
  });
}
