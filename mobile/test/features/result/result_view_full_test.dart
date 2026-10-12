// Uji regresi: layar "Detail Inspeksi" penuh (termasuk kartu rekomendasi
// bertab dan kartu penilaian pribadi) tidak overflow pada lebar layar wajar.
//
// Font Inter asli dimuat agar lebar teks realistis (font bawaan widget test
// bersifat monospace sehingga melebih-lebihkan lebar teks).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/core/theme/roastmate_theme.dart';
import 'package:pbl_sem5/features/result/data/sources/mock_inspection_source.dart';
import 'package:pbl_sem5/features/result/presentation/views/result_view.dart';

Future<void> _loadInter() async {
  final loader = FontLoader('Inter');
  for (final file in const [
    'Inter-Regular.ttf',
    'Inter-Medium.ttf',
    'Inter-SemiBold.ttf',
    'Inter-Bold.ttf',
  ]) {
    loader.addFont(rootBundle.load('assets/fonts/$file'));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadInter();
  });

  for (final width in const [390.0, 360.0, 320.0]) {
    testWidgets('Detail Inspeksi penuh tanpa overflow @ ${width.toInt()}dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width * 3, 800 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: roastmateTheme,
            home: InspectionDetailScreen(result: mockInspectionResult),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
