// Widget test: kartu rekomendasi seduh dengan navigasi chip bertumpuk ke bawah.
//
// Fokus: chip default = metode yang direkomendasikan (berbadge), isi tab
// alternatif tersembunyi sampai chip-nya dipilih, struktur isi tiap tab
// identik, dan CTA mengarah ke Detail Resep.

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

/// Label struktur parameter yang dipakai sama rata di setiap tab.
const _metricLabels = <String>[
  'Rasio Seduh',
  'Suhu Air',
  'Tingkat Gilingan',
  'Target Waktu',
];

void main() {
  testWidgets('Chip default adalah metode direkomendasikan + berbadge', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Chip navigasi tampil untuk semua opsi (utama + alternatif).
    expect(find.text('Pour Over'), findsOneWidget);
    expect(find.text('Aeropress'), findsOneWidget);
    expect(find.text('French Press'), findsOneWidget);

    // Hanya chip utama yang berbadge "Direkomendasikan".
    expect(find.text('Direkomendasikan'), findsOneWidget);

    // Isi tab utama tampil lengkap.
    expect(find.text('Pour Over (V60) — Clean & Bright'), findsOneWidget);
    for (final label in _metricLabels) {
      expect(find.text(label), findsOneWidget);
    }

    // Isi tab alternatif tersembunyi secara default.
    expect(find.text('Aeropress (Inverted)'), findsNothing);
  });

  testWidgets('Memilih chip alternatif menampilkan isi berstruktur sama', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aeropress'));
    await tester.pumpAndSettle();

    // Judul alternatif tampil, judul utama hilang.
    expect(find.text('Aeropress (Inverted)'), findsOneWidget);
    expect(find.text('Pour Over (V60) — Clean & Bright'), findsNothing);

    // Struktur parameter identik dengan tab utama.
    for (final label in _metricLabels) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Medium-Fine'), findsOneWidget);

    // Badge tetap hanya milik metode utama.
    expect(find.text('Direkomendasikan'), findsOneWidget);
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
