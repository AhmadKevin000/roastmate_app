import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show StateNotifier;

import '../../../../core/database/app_database.dart';
import '../../../../features/analysis/data/sources/analysis_repository.dart';
import '../../../../shared/models/analysis_result.dart';
import '../../domain/entities/analysis_detail.dart';

/// State layar Detail Inspeksi (Plan 3): loading → content, atau error
/// bila id tidak ada / tak terbaca.
@immutable
class ResultState {
  const ResultState.loading()
      : loading = true,
        content = null,
        error = null;

  const ResultState.content(AnalysisDetail detail)
      : loading = false,
        content = detail,
        error = null;

  const ResultState.error(String message)
      : loading = false,
        content = null,
        error = message;

  final bool loading;
  final AnalysisDetail? content;
  final String? error;
}

/// Muat detail analisis dari SQLite per [analysisId] (Plan 3 §6).
///
/// - [analysisId] null (route `draft` setelah scan) → [fallback]
///   dibungkus [AnalysisDetail] tanpa sentuh DB.
/// - Baca DB gagal (mis. lingkungan tanpa SQLite) dan [fallback] ada →
///   fallback dipakai, bukan error (AC-04 alur scan).
/// - Id tidak ada di DB → error state.
class ResultViewModel extends StateNotifier<ResultState> {
  ResultViewModel({required this.analysisId, this.fallback})
      : super(const ResultState.loading());

  /// Id baris `analyses`; null bila belum tersimpan (draft).
  final int? analysisId;

  /// Data in-memory dari alur scan (route extra).
  final InspectionResult? fallback;

  /// [state] yang aman dibaca dari luar subclass (UI & test).
  ResultState get viewState => state;

  Future<void> load() async {
    if (analysisId == null) {
      final fb = fallback;
      state = fb == null
          ? const ResultState.error('Analisis tidak ditemukan')
          : ResultState.content(_detailFromFallback(fb));
      return;
    }

    try {
      final db = await AppDatabase.instance.database;
      final detail = await AnalysisRepository(db).getDetail(analysisId!);
      state = detail == null
          ? const ResultState.error('Analisis tidak ditemukan')
          : ResultState.content(detail);
    } catch (_) {
      final fb = fallback;
      state = fb == null
          ? const ResultState.error('Gagal memuat detail inspeksi')
          : ResultState.content(_detailFromFallback(fb));
    }
  }

  /// Bungkus [InspectionResult] in-memory menjadi [AnalysisDetail];
  /// rekomendasi/alternatif/summaryText ikut dari result itu sendiri
  /// (bukan dari join DB).
  AnalysisDetail _detailFromFallback(InspectionResult result) {
    return AnalysisDetail(
      analysisId: result.analysisId ?? 0,
      result: result,
      imagePath: result.imagePath,
      recommendation: result.recommendation,
      alternatives: result.alternatives,
      summaryText: result.summaryText,
    );
  }
}
