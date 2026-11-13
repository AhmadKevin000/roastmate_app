// Widget test: halaman Beranda terhadap data SQLite (di-fake di test).
//
// Fokus:
// - angka agregat & kartu "Analisis Terakhir" berasal dari repository;
// - riwayat kosong menampilkan empty state, bukan angka palsu;
// - error pembacaan menampilkan pesan + tombol coba lagi;
// - "Lihat Semua" berpindah ke tab Analisis;
// - header tetap tampil di atas saat konten di-scroll.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pbl_sem5/core/widgets/roastmate_app_header.dart';
import 'package:pbl_sem5/features/home/data/repositories/home_repository.dart';
import 'package:pbl_sem5/features/home/data/sources/analysis_summary_source.dart';
import 'package:pbl_sem5/features/home/domain/entities/home_summary.dart';
import 'package:pbl_sem5/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:pbl_sem5/features/home/presentation/views/home_view.dart';

class _FakeSummarySource implements AnalysisSummarySource {
  _FakeSummarySource(this.snapshot, {this.error});

  final AnalysisSummarySnapshot snapshot;
  final Object? error;

  @override
  Future<AnalysisSummarySnapshot> fetchSummary({
    int recentLimit = kHomeRecentLimit,
  }) async {
    if (error != null) throw error!;
    return snapshot;
  }
}

const AnalysisSummarySnapshot _emptySnapshot = AnalysisSummarySnapshot(
  totalAnalyses: 0,
  averageScore: null,
  speciesCounts: <String, int>{},
  recentRows: <Map<String, Object?>>[],
);

AnalysisSummarySnapshot _filledSnapshot() => AnalysisSummarySnapshot(
      totalAnalyses: 2,
      averageScore: 84.5,
      speciesCounts: const <String, int>{
        SpeciesLabels.arabica: 1,
        SpeciesLabels.robusta: 1,
      },
      recentRows: <Map<String, Object?>>[
        <String, Object?>{
          'id': 1,
          'name': 'Gayo Natural Anaerob',
          'created_at': '2026-03-12T10:24:00',
          'species': SpeciesLabels.arabica,
          'visible_beans': 32,
          'quality_score': 88,
        },
        <String, Object?>{
          'id': 2,
          'name': 'Temanggung Fine Robusta',
          'created_at': '2026-03-10T16:15:00',
          'species': SpeciesLabels.robusta,
          'visible_beans': 28,
          'quality_score': 82,
        },
      ],
    );

Widget _app({AnalysisSummarySnapshot? snapshot, Object? error}) {
  return ProviderScope(
    overrides: [
      homeRepositoryProvider.overrideWithValue(
        HomeRepository(
          _FakeSummarySource(snapshot ?? _emptySnapshot, error: error),
        ),
      ),
    ],
    child: MaterialApp.router(
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
            path: '/scan/setup',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('SCAN:SETUP'))),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('menampilkan angka agregat dan kartu dari repository', (
    tester,
  ) async {
    await tester.pumpWidget(_app(snapshot: _filledSnapshot()));
    await tester.pumpAndSettle();

    // Agregat: total batch, rata-rata, grade turunan.
    expect(find.text('Total 2 Batch'), findsOneWidget);
    expect(find.text('84.5'), findsOneWidget);
    expect(find.text('GRADE: PREMIUM'), findsOneWidget);

    // Kartu terakhir memakai nama & skor dari baris database.
    expect(find.text('Gayo Natural Anaerob'), findsOneWidget);
    expect(find.text('Temanggung Fine Robusta'), findsOneWidget);
    expect(find.text('32 biji terlihat'), findsOneWidget);
    expect(find.text('88'), findsOneWidget);
    expect(find.text('12 Mar, 10:24 • Arabica'), findsOneWidget);
  });

  testWidgets('riwayat kosong menampilkan empty state, bukan angka palsu', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Belum ada analisis tersimpan'), findsOneWidget);
    expect(find.text('Analisis Terakhir'), findsNothing);
    expect(find.text('Komposisi Jenis Biji'), findsNothing);
    // CTA scan tetap tersedia supaya pengguna bisa mulai mengisi riwayat.
    expect(find.text('Mulai Scan'), findsOneWidget);
  });

  testWidgets('error pembacaan menampilkan pesan dan tombol coba lagi', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(error: StateError('database tidak bisa dibuka')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Riwayat analisis gagal dibaca'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.text('Belum ada analisis tersimpan'), findsNothing);
  });

  testWidgets('Lihat Semua berpindah ke tab Analisis', (tester) async {
    await tester.pumpWidget(_app(snapshot: _filledSnapshot()));
    await tester.pumpAndSettle();

    final seeAll = find.text('Lihat Semua');
    await tester.ensureVisible(seeAll);
    await tester.pumpAndSettle();
    await tester.tap(seeAll);
    await tester.pumpAndSettle();

    expect(find.text('TAB:ANALISIS'), findsOneWidget);
  });

  testWidgets('tombol scan membuka setup scan', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final scan = find.text('Mulai Scan');
    await tester.ensureVisible(scan);
    await tester.pumpAndSettle();
    await tester.tap(scan);
    await tester.pumpAndSettle();

    expect(find.text('SCAN:SETUP'), findsOneWidget);
  });

  testWidgets('Header tetap tampil setelah konten di-scroll', (tester) async {
    await tester.pumpWidget(_app(snapshot: _filledSnapshot()));
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
