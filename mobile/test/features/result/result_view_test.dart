// Uji regresi layout widget Detail Inspeksi pada layar sempit.
//
// Fokus:
//  - QualityScoreCard: label/chip turun ke baris baru bila ruang tidak cukup.
//  - BrewRecommendationCard: tinggi sel mengikuti isi (1–2 baris) tanpa
//    bottom overflow.
//
// Font Inter asli dimuat agar lebar teks realistis (font bawaan widget test
// bersifat monospace sehingga melebih-lebihkan lebar teks).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/core/theme/roastmate_theme.dart';
import 'package:pbl_sem5/features/result/data/sources/mock_inspection_source.dart';
import 'package:pbl_sem5/features/result/presentation/widgets/brew_recommendation_card.dart';
import 'package:pbl_sem5/features/result/presentation/widgets/quality_score_card.dart';

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

Widget _host(double width, Widget child) => MaterialApp(
      theme: roastmateTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadInter();
  });

  for (final width in const [320.0, 280.0]) {
    testWidgets('QualityScoreCard tanpa overflow @ ${width.toInt()}dp',
        (tester) async {
      await tester.pumpWidget(
        _host(width, QualityScoreCard(result: mockInspectionResult)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('BrewRecommendationCard tanpa overflow @ ${width.toInt()}dp',
        (tester) async {
      await tester.pumpWidget(
        _host(width, BrewRecommendationCard(result: mockInspectionResult)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
