import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/models/personal_rating.dart';
import '../../../analysis/data/sources/analysis_repository.dart';

/// Pembuka repository penilaian; bisa diganti pada test (mis. DB in-memory).
typedef AnalysisRepositoryOpener = Future<AnalysisRepository> Function();

Future<AnalysisRepository> _openDefaultRepository() async =>
    AnalysisRepository(await AppDatabase.instance.database);

/// State personal rating per batch (key = `batchLabel`).
///
/// Sejak skema v8 (D-31) penilaian disimpan permanen di kolom
/// `analyses.personal_rating` / `personal_rating_note`. Map di kelas ini tetap
/// dipakai sebagai state sesi supaya perubahan langsung terlihat di UI (dan
/// tetap berfungsi untuk hasil scan yang belum punya baris DB).
class PersonalRatingViewModel
    extends StateNotifier<Map<String, PersonalRating>> {
  PersonalRatingViewModel({AnalysisRepositoryOpener? repositoryOpener})
    : _repositoryOpener = repositoryOpener ?? _openDefaultRepository,
      super(const {});

  final AnalysisRepositoryOpener _repositoryOpener;

  PersonalRating ratingFor(String key) => state[key] ?? const PersonalRating();

  void setStars(String key, int stars) {
    final current = ratingFor(key);
    state = {...state, key: current.copyWith(stars: stars)};
  }

  void setNote(String key, String note) {
    final current = ratingFor(key);
    state = {...state, key: current.copyWith(note: note)};
  }

  /// Simpan penilaian untuk [key] ke baris `analyses` [analysisId].
  ///
  /// `false` bila belum ada bintang atau penulisan DB gagal (UI menampilkan
  /// pesan gagal). Tidak melempar exception ke widget.
  Future<bool> persist(String key, int analysisId) async {
    final rating = ratingFor(key);
    if (!rating.hasRating) return false;
    try {
      final repository = await _repositoryOpener();
      await repository.savePersonalRating(
        analysisId,
        stars: rating.stars,
        note: rating.note,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Provider personal rating (state sesi + penulisan SQLite).
final personalRatingProvider =
    StateNotifierProvider<PersonalRatingViewModel, Map<String, PersonalRating>>(
      (ref) => PersonalRatingViewModel(),
    );
