// Widget test: navigasi pada halaman Beranda.
//
// Fokus:
// - kartu "Analisis Terakhir" membuka halaman hasil analisis (Detail Inspeksi)
//   dengan data yang sama seperti yang tampil di kartu;
// - "Lihat Semua" berpindah ke tab Analisis;
// - header tetap tampil di atas saat konten di-scroll.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pbl_sem5/core/widgets/roastmate_app_header.dart';
import 'package:pbl_sem5/features/analysis/data/sources/mock_analysis_history.dart';
import 'package:pbl_sem5/features/home/presentation/views/home_view.dart';
import 'package:pbl_sem5/shared/models/analysis_result.dart';

/// Router uji: `/home` + tujuan detail + tab Analisis (dibedakan lewat teks).
Widget _app() => MaterialApp.router(
  routerConfig: GoRouter(
    initialLocation: '/home',
    routes: <RouteBase>[
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/history',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('TAB:ANALISIS'))),
      ),
      GoRoute(
        path: '/result/:analysisId',
        builder: (context, state) {
          final result = state.extra as InspectionResult?;
          return Scaffold(
            body: Center(child: Text('RESULT:${result?.batchName ?? 'null'}')),
          );
        },
      ),
    ],
  ),
);

void main() {
  testWidgets('Kartu analisis terakhir membuka halaman hasil analisis', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Kartu menampilkan batch teratas dari data riwayat.
    final first = mockAnalysisHistory.first;
    final card = find.text(first.batchName);
    expect(card, findsOneWidget);

    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();

    // Membuka Detail Inspeksi dengan batch yang sama.
    expect(find.text('RESULT:${first.batchName}'), findsOneWidget);
  });

  testWidgets('Lihat Semua berpindah ke tab Analisis', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final seeAll = find.text('Lihat Semua');
    await tester.ensureVisible(seeAll);
    await tester.pumpAndSettle();
    await tester.tap(seeAll);
    await tester.pumpAndSettle();

    expect(find.text('TAB:ANALISIS'), findsOneWidget);
  });

  testWidgets('Header tetap tampil setelah konten di-scroll', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byType(RoastmateAppHeader), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    // Header pinned (bukan ikut ter-scroll).
    expect(find.byType(RoastmateAppHeader), findsOneWidget);
    expect(find.text('Roastmate'), findsOneWidget);
  });
}
