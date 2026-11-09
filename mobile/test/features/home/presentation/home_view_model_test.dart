import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/features/home/data/repositories/home_repository.dart';
import 'package:pbl_sem5/features/home/data/sources/analysis_summary_source.dart';
import 'package:pbl_sem5/features/home/domain/entities/home_summary.dart';
import 'package:pbl_sem5/features/home/presentation/viewmodels/home_view_model.dart';

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

ProviderContainer _container(AnalysisSummarySource source) {
  final container = ProviderContainer(
    overrides: [
      homeRepositoryProvider.overrideWithValue(HomeRepository(source)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('state awal memuat lalu berisi ringkasan dari repository', () async {
    final container = _container(
      _FakeSummarySource(
        AnalysisSummarySnapshot(
          totalAnalyses: 2,
          averageScore: 84.5,
          speciesCounts: const <String, int>{SpeciesLabels.arabica: 2},
          recentRows: <Map<String, Object?>>[
            <String, Object?>{
              'id': 1,
              'name': 'Gayo',
              'created_at': '2026-03-12T10:24:00',
              'species': SpeciesLabels.arabica,
              'visible_beans': 24,
              'quality_score': 88,
            },
          ],
        ),
      ),
    );

    final notifier = container.read(homeViewModelProvider.notifier);
    expect(container.read(homeViewModelProvider).isLoading, isTrue);

    await notifier.load();

    final state = container.read(homeViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.hasError, isFalse);
    expect(state.summary.totalAnalyses, 2);
    expect(state.summary.recentAnalyses.single.name, 'Gayo');
  });

  test('error repository menjadi pesan di state, bukan exception ke UI',
      () async {
    final container = _container(
      _FakeSummarySource(
        const AnalysisSummarySnapshot(
          totalAnalyses: 0,
          averageScore: null,
          speciesCounts: <String, int>{},
          recentRows: <Map<String, Object?>>[],
        ),
        error: StateError('disk penuh'),
      ),
    );

    await container.read(homeViewModelProvider.notifier).load();

    final state = container.read(homeViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.hasError, isTrue);
    expect(state.errorMessage, contains('disk penuh'));
    expect(state.summary.isEmpty, isTrue);
  });

  test('riwayat kosong menghasilkan state tanpa error dengan summary kosong',
      () async {
    final container = _container(
      _FakeSummarySource(
        const AnalysisSummarySnapshot(
          totalAnalyses: 0,
          averageScore: null,
          speciesCounts: <String, int>{},
          recentRows: <Map<String, Object?>>[],
        ),
      ),
    );

    await container.read(homeViewModelProvider.notifier).load();

    final state = container.read(homeViewModelProvider);
    expect(state.hasError, isFalse);
    expect(state.summary.isEmpty, isTrue);
  });
}
