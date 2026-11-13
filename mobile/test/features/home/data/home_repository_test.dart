import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/features/home/data/repositories/home_repository.dart';
import 'package:pbl_sem5/features/home/data/sources/analysis_summary_source.dart';
import 'package:pbl_sem5/features/home/domain/entities/home_summary.dart';
import 'package:pbl_sem5/shared/enums/indicative_grade.dart';

/// Sumber palsu supaya test tidak menyentuh SQLite.
class _FakeSummarySource implements AnalysisSummarySource {
  _FakeSummarySource(this.snapshot);

  final AnalysisSummarySnapshot snapshot;
  int callCount = 0;
  int? lastRecentLimit;

  @override
  Future<AnalysisSummarySnapshot> fetchSummary({
    int recentLimit = kHomeRecentLimit,
  }) async {
    callCount++;
    lastRecentLimit = recentLimit;
    return snapshot;
  }
}

class _ThrowingSummarySource implements AnalysisSummarySource {
  @override
  Future<AnalysisSummarySnapshot> fetchSummary({
    int recentLimit = kHomeRecentLimit,
  }) async {
    throw StateError('database tidak bisa dibuka');
  }
}

Map<String, Object?> _row({
  int id = 1,
  String? name = 'Gayo Natural Anaerob',
  String createdAt = '2026-03-12T10:24:00',
  String? species = SpeciesLabels.arabica,
  int? visibleBeans = 24,
  int? qualityScore = 82,
}) {
  return <String, Object?>{
    'id': id,
    'name': name,
    'created_at': createdAt,
    'species': species,
    'visible_beans': visibleBeans,
    'quality_score': qualityScore,
  };
}

void main() {
  group('HomeRepository.loadSummary', () {
    test('memetakan potret agregat menjadi entity domain', () async {
      final source = _FakeSummarySource(
        AnalysisSummarySnapshot(
          totalAnalyses: 2,
          averageScore: 84.5,
          speciesCounts: <String, int>{SpeciesLabels.arabica: 1, SpeciesLabels.robusta: 1},
          recentRows: <Map<String, Object?>>[_row()],
        ),
      );

      final summary = await HomeRepository(source).loadSummary();

      expect(summary.totalAnalyses, 2);
      expect(summary.averageScore, 84.5);
      expect(summary.averageGrade, IndicativeGrade.premium);
      expect(summary.countOf(SpeciesLabels.arabica), 1);
      expect(summary.recentAnalyses, hasLength(1));

      final item = summary.recentAnalyses.single;
      expect(item.id, 1);
      expect(item.name, 'Gayo Natural Anaerob');
      expect(item.createdAt, DateTime(2026, 3, 12, 10, 24));
      expect(item.species, SpeciesLabels.arabica);
      expect(item.visibleBeans, 24);
      expect(item.qualityScore, 82);
      expect(item.grade, IndicativeGrade.premium);
      expect(item.shortDateLabel, '12 Mar, 10:24');
    });

    test('riwayat kosong menghasilkan ringkasan kosong tanpa error', () async {
      final source = _FakeSummarySource(
        const AnalysisSummarySnapshot(
          totalAnalyses: 0,
          averageScore: null,
          speciesCounts: <String, int>{},
          recentRows: <Map<String, Object?>>[],
        ),
      );

      final summary = await HomeRepository(source).loadSummary();

      expect(summary.isEmpty, isTrue);
      expect(summary.averageScore, 0);
      expect(summary.recentAnalyses, isEmpty);
    });

    test('meneruskan batas jumlah kartu terakhir ke sumber data', () async {
      final source = _FakeSummarySource(
        const AnalysisSummarySnapshot(
          totalAnalyses: 0,
          averageScore: null,
          speciesCounts: <String, int>{},
          recentRows: <Map<String, Object?>>[],
        ),
      );

      await HomeRepository(source).loadSummary(recentLimit: 5);

      expect(source.lastRecentLimit, 5);
      expect(source.callCount, 1);
    });

    test('nama kosong memakai label cadangan, bukan string kosong', () async {
      final source = _FakeSummarySource(
        AnalysisSummarySnapshot(
          totalAnalyses: 1,
          averageScore: 70,
          speciesCounts: const <String, int>{SpeciesLabels.arabica: 1},
          recentRows: <Map<String, Object?>>[_row(name: '   ')],
        ),
      );

      final summary = await HomeRepository(source).loadSummary();

      expect(summary.recentAnalyses.single.name, 'Batch tanpa nama');
    });

    test('species kosong tidak membuat kartu gagal tampil', () async {
      final source = _FakeSummarySource(
        AnalysisSummarySnapshot(
          totalAnalyses: 1,
          averageScore: 70,
          speciesCounts: const <String, int>{SpeciesLabels.arabica: 1},
          recentRows: <Map<String, Object?>>[_row(species: null)],
        ),
      );

      final summary = await HomeRepository(source).loadSummary();

      expect(summary.recentAnalyses.single.species, SpeciesLabels.unknown);
    });

    test('created_at rusak ditolak, bukan diam-diam jadi epoch', () async {
      final source = _FakeSummarySource(
        AnalysisSummarySnapshot(
          totalAnalyses: 1,
          averageScore: 70,
          speciesCounts: const <String, int>{SpeciesLabels.arabica: 1},
          recentRows: <Map<String, Object?>>[_row(createdAt: 'bukan tanggal')],
        ),
      );

      expect(HomeRepository(source).loadSummary(), throwsFormatException);
    });

    test('error dari sumber data diteruskan ke pemanggil', () async {
      expect(
        HomeRepository(_ThrowingSummarySource()).loadSummary(),
        throwsStateError,
      );
    });
  });
}
