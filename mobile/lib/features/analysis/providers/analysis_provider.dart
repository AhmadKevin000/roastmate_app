import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/analysis_repository.dart';
import '../../../data/mock_inspection.dart';
import '../../../domain/inspection_result.dart';

final analysisRepositoryProvider = Provider<AnalysisRepository>((ref) {
  return AnalysisRepository();
});

/// Mengambil seluruh riwayat analisis dari database SQLite.
final allAnalysesProvider = FutureProvider<List<InspectionResult>>((ref) async {
  final repo = ref.watch(analysisRepositoryProvider);
  // Pastikan ada seed sample jika database masih baru
  await repo.ensureSeedData(mockInspectionResult);
  return await repo.getAllInspections();
});

/// Mengambil detail satu analisis berdasarkan ID.
final inspectionDetailProvider = FutureProvider.family<InspectionResult?, int>((ref, id) async {
  final repo = ref.watch(analysisRepositoryProvider);
  return await repo.getInspectionById(id);
});

/// Notifier untuk mengelola state halaman Detail Inspeksi / Hasil Scan.
class InspectionDetailState {
  final bool isLoading;
  final String? errorMessage;
  final InspectionResult? result;

  const InspectionDetailState({
    this.isLoading = false,
    this.errorMessage,
    this.result,
  });

  InspectionDetailState copyWith({
    bool? isLoading,
    String? errorMessage,
    InspectionResult? result,
  }) {
    return InspectionDetailState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      result: result ?? this.result,
    );
  }
}

class InspectionDetailNotifier extends StateNotifier<InspectionDetailState> {
  final AnalysisRepository _repository;

  InspectionDetailNotifier(this._repository, [InspectionResult? initialResult])
      : super(InspectionDetailState(result: initialResult));

  /// Memuat data inspeksi dari SQLite berdasarkan ID.
  Future<void> loadInspection(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.getInspectionById(id);
      if (res != null) {
        state = state.copyWith(isLoading: false, result: res);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Data analisis dengan ID $id tidak ditemukan.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal membaca database: $e',
      );
    }
  }

  /// Menyimpan hasil analisis baru ke SQLite.
  Future<int?> saveInspection(InspectionResult result) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newId = await _repository.saveInspection(result);
      final saved = await _repository.getInspectionById(newId);
      state = state.copyWith(isLoading: false, result: saved ?? result.copyWith(id: newId));
      return newId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menyimpan ke database: $e',
      );
      return null;
    }
  }

  /// Inisialisasi awal dengan data sample jika belum ada.
  Future<void> initializeWithSampleIfNeeded(InspectionResult sample) async {
    if (state.result != null) return;
    state = state.copyWith(isLoading: true);
    try {
      await _repository.ensureSeedData(sample);
      final list = await _repository.getAllInspections();
      if (list.isNotEmpty) {
        state = state.copyWith(isLoading: false, result: list.first);
      } else {
        state = state.copyWith(isLoading: false, result: sample);
      }
    } catch (e) {
      // Fallback ke sample in-memory jika SQLite belum siap
      state = state.copyWith(isLoading: false, result: sample);
    }
  }
}

final inspectionDetailNotifierProvider =
    StateNotifierProvider.autoDispose<InspectionDetailNotifier, InspectionDetailState>((ref) {
  final repo = ref.watch(analysisRepositoryProvider);
  return InspectionDetailNotifier(repo);
});

