import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/home_repository.dart';
import '../../data/sources/analysis_summary_source.dart';
import '../../domain/entities/home_summary.dart';

/// State tab Beranda.
@immutable
class HomeState {
  const HomeState({
    this.isLoading = true,
    this.summary = const HomeSummary.empty(),
    this.errorMessage,
  });

  final bool isLoading;
  final HomeSummary summary;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
}

/// ViewModel Beranda (MVVM, pola sama dengan `BrewViewModel`).
///
/// Membaca ringkasan dari SQLite lewat [HomeRepository]. Tidak ada data mock
/// maupun akses jaringan di jalur ini.
class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel(this._repository) : super(const HomeState()) {
    load();
  }

  final HomeRepository _repository;

  Future<void> load() async {
    state = const HomeState(isLoading: true);
    try {
      final summary = await _repository.loadSummary();
      if (!mounted) return;
      state = HomeState(isLoading: false, summary: summary);
    } catch (error) {
      if (!mounted) return;
      state = HomeState(isLoading: false, errorMessage: '$error');
    }
  }
}

/// Repository Beranda (dapat di-override pada test).
final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepository(SqliteAnalysisSummarySource()),
);

/// State Beranda untuk widget.
final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>(
  (ref) => HomeViewModel(ref.watch(homeRepositoryProvider)),
);
