// Smoke test aplikasi: shell navigasi tampil dan Beranda membaca data
// lewat provider (repository di-fake agar test tidak menyentuh SQLite).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pbl_sem5/app/app.dart';
import 'package:pbl_sem5/app/main_shell.dart';
import 'package:pbl_sem5/features/home/data/repositories/home_repository.dart';
import 'package:pbl_sem5/features/home/data/sources/analysis_summary_source.dart';
import 'package:pbl_sem5/features/home/presentation/viewmodels/home_view_model.dart';

class _EmptySummarySource implements AnalysisSummarySource {
  @override
  Future<AnalysisSummarySnapshot> fetchSummary({
    int recentLimit = kHomeRecentLimit,
  }) async {
    return const AnalysisSummarySnapshot(
      totalAnalyses: 0,
      averageScore: null,
      speciesCounts: <String, int>{},
      recentRows: <Map<String, Object?>>[],
    );
  }
}

void main() {
  testWidgets('Aplikasi menampilkan shell navigasi dan Beranda', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeRepositoryProvider.overrideWithValue(
            HomeRepository(_EmptySummarySource()),
          ),
        ],
        child: const RoastmateApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Belum ada analisis tersimpan'), findsOneWidget);
  });
}
