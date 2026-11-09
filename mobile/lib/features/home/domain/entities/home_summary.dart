import '../../../../shared/enums/indicative_grade.dart';
import '../../../../shared/utils/date_formatter.dart';

/// Nama species kanonik (Title Case) sesuai `docs/DATABASE_SCHEMA.md` §11
/// dan D-13. `uncertain` bukan species, melainkan status tampilan.
abstract final class SpeciesLabels {
  static const String arabica = 'Arabica';
  static const String robusta = 'Robusta';
  static const String mixed = 'Mixed';

  /// Urutan tampil pada kartu komposisi.
  static const List<String> all = <String>[arabica, robusta, mixed];

  /// Label cadangan bila kolom `species` kosong (data lama/rusak).
  static const String unknown = 'Tidak diketahui';
}

/// Satu baris `analyses` yang dibutuhkan kartu "Analisis Terakhir".
class HomeAnalysisSummary {
  const HomeAnalysisSummary({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.species,
    required this.visibleBeans,
    required this.qualityScore,
  });

  final int id;
  final String name;
  final DateTime createdAt;
  final String species;
  final int visibleBeans;
  final int qualityScore;

  IndicativeGrade get grade => gradeForScore(qualityScore);

  /// Label tanggal ringkas, mis. `12 Mar, 10:24`.
  String get shortDateLabel => formatShortDateLabel(createdAt);
}

/// Ringkasan isi tab Beranda.
///
/// Dihitung dari seluruh riwayat analisis lokal. Komposisi species memakai
/// `species` dominan per analisis (D-15), bukan sebaran per biji.
class HomeSummary {
  const HomeSummary({
    required this.totalAnalyses,
    required this.averageScore,
    required this.speciesCounts,
    required this.recentAnalyses,
  });

  /// Kondisi awal: belum ada analisis tersimpan.
  const HomeSummary.empty()
      : totalAnalyses = 0,
        averageScore = 0,
        speciesCounts = const <String, int>{},
        recentAnalyses = const <HomeAnalysisSummary>[];

  final int totalAnalyses;

  /// Rata-rata quality score 0–100; 0 bila belum ada analisis.
  final double averageScore;

  /// Jumlah analisis per species dominan (`Arabica`/`Robusta`/`Mixed`).
  final Map<String, int> speciesCounts;

  /// Analisis terbaru, sudah terurut dari yang paling baru.
  final List<HomeAnalysisSummary> recentAnalyses;

  bool get isEmpty => totalAnalyses == 0;

  int countOf(String species) => speciesCounts[species] ?? 0;

  /// Porsi species terhadap seluruh analisis (0.0–1.0).
  double shareOf(String species) =>
      totalAnalyses == 0 ? 0 : countOf(species) / totalAnalyses;

  /// Grade indikatif dari rata-rata skor (D-02). `grade` tidak disimpan di DB.
  IndicativeGrade get averageGrade => gradeForScore(averageScore);
}
