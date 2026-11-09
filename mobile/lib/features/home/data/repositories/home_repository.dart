import '../../domain/entities/home_summary.dart';
import '../sources/analysis_summary_source.dart';

/// Akses data Beranda: memetakan potret agregat SQLite ke entity domain.
///
/// Belum ada operasi tulis. Penulisan riwayat dilakukan oleh alur scan
/// (belum terintegrasi), sehingga Beranda hanya membaca.
class HomeRepository {
  HomeRepository(this._source);

  final AnalysisSummarySource _source;

  Future<HomeSummary> loadSummary({int recentLimit = kHomeRecentLimit}) async {
    final snapshot = await _source.fetchSummary(recentLimit: recentLimit);

    return HomeSummary(
      totalAnalyses: snapshot.totalAnalyses,
      averageScore: snapshot.averageScore ?? 0,
      speciesCounts: Map<String, int>.unmodifiable(snapshot.speciesCounts),
      recentAnalyses: List<HomeAnalysisSummary>.unmodifiable(
        snapshot.recentRows.map(_toSummary),
      ),
    );
  }

  HomeAnalysisSummary _toSummary(Map<String, Object?> row) {
    final rawDate = row['created_at'] as String?;
    final createdAt = rawDate == null ? null : DateTime.tryParse(rawDate);
    if (createdAt == null) {
      throw FormatException('created_at tidak valid pada analyses: $rawDate');
    }

    final rawName = (row['name'] as String?)?.trim();

    return HomeAnalysisSummary(
      id: (row['id'] as num).toInt(),
      // Fallback tampilan; baris ditulis oleh aplikasi sendiri.
      name: (rawName == null || rawName.isEmpty) ? 'Batch tanpa nama' : rawName,
      createdAt: createdAt,
      species: (row['species'] as String?) ?? SpeciesLabels.unknown,
      visibleBeans: (row['visible_beans'] as num?)?.toInt() ?? 0,
      qualityScore: (row['quality_score'] as num?)?.toInt() ?? 0,
    );
  }
}
