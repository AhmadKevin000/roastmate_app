// Widget test fitur Brew (Resep Seduh & Detail Resep).
//
// Mengacu ke `docs/PRD.md` FR-06/FR-07 dan `docs/DECISIONS.md` D-01.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/features/brew/views/brew_catalog_screen.dart';

Widget _app() => const ProviderScope(
      child: MaterialApp(home: BrewCatalogScreen()),
    );

void main() {
  testWidgets('Katalog menampilkan metode beserta parameter (FR-06)',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Katalog Metode Seduh'), findsOneWidget);
    expect(find.text('V60 / Pour Over'), findsOneWidget);
    expect(find.text('French Press'), findsOneWidget);
    expect(find.text('Kopi Tubruk Tradisional'), findsOneWidget);
    expect(find.text('Mulai Setup'), findsNWidgets(3));
  });

  testWidgets('Katalog menampilkan rasio yang dihitung (D-10)', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // 225 ml / 15 g = 1:15
    expect(find.text('1:15'), findsOneWidget);
    // 252 ml / 18 g = 1:14
    expect(find.text('1:14'), findsOneWidget);
    // 180 ml / 15 g = 1:12
    expect(find.text('1:12'), findsOneWidget);
  });

  testWidgets('Mulai Setup membuka Detail Resep lengkap tanpa timer (FR-07, D-01)',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final startButton = find.text('Mulai Setup').first;
    await tester.ensureVisible(startButton);
    await tester.pumpAndSettle();
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    // Ringkasan, persiapan, langkah, dan tips rasa.
    expect(find.text('Berat'), findsOneWidget);
    expect(find.text('Total Air'), findsOneWidget);
    expect(find.text('Persiapan & Alat Seduh'), findsOneWidget);
    expect(find.text('Panduan Langkah'), findsOneWidget);
    expect(find.text('Blooming'), findsOneWidget);
    expect(find.text('Artisan Pro-Tips: Kalibrasi Rasa'), findsOneWidget);

    // D-01: panduan statis — tidak ada kontrol timer interaktif.
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    expect(find.byIcon(Icons.pause), findsNothing);
    expect(find.byIcon(Icons.stop), findsNothing);
  });
}
