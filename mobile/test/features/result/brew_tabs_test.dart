// Widget test: kartu rekomendasi seduh sebagai tabs.
//
// Fokus: tab default = metode utama, tab alternatif tersembunyi sampai dipilih,
// dan CTA mengarah ke Detail Resep.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pbl_sem5/features/result/data/sources/mock_inspection_source.dart';
import 'package:pbl_sem5/features/result/presentation/widgets/brew_recommendation_card.dart';

Widget _app() => MaterialApp.router(
  routerConfig: GoRouter(
    initialLocation: '/result/1',
    routes: <RouteBase>[
      GoRoute(
        path: '/result/:analysisId',
        builder: (context, state) => Scaffold(
          body: SingleChildScrollView(
            child: BrewRecommendationCard(result: mockInspectionResult),
          ),
        ),
      ),
      GoRoute(
        path: '/brewing/:methodId',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('DETAIL:${state.pathParameters['methodId']}'),
          ),
        ),
      ),
    ],
  ),
);

void main() {
  testWidgets('Tab default adalah metode yang direkomendasikan', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Label tab utama + isi parameter lengkapnya.
    expect(find.text('Pour Over'), findsOneWidget);
    expect(find.text('Pour Over (V60) — Clean & Bright'), findsOneWidget);
    expect(find.text('Rasio Seduh'), findsOneWidget);

    // Isi tab alternatif tersembunyi default.
    expect(find.text('Aeropress (Inverted)'), findsNothing);
  });

  testWidgets('Pilih tab alternatif menampilkan opsi lain', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aeropress'));
    await tester.pumpAndSettle();

    expect(find.text('Aeropress (Inverted)'), findsOneWidget);
    expect(find.text('Pour Over (V60) — Clean & Bright'), findsNothing);
  });

  testWidgets('CTA tab utama membuka Detail Resep (FR-07)', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final cta = find.text('Lihat Cara Penyajian');
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pumpAndSettle();

    expect(find.text('DETAIL:M001'), findsOneWidget);
  });

  testWidgets('CTA tab alternatif tanpa resep katalog dinonaktifkan', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aeropress'));
    await tester.pumpAndSettle();

    final cta = find.text('Detail Resep Belum Tersedia');
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();

    expect(cta, findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });
}
