import 'inspection_result.dart';

/// Satu baris riwayat analisis untuk daftar di tab Analisis.
///
/// Versi ringkas dari [InspectionResult]: hanya memuat field yang tampil di
/// kartu riwayat (tanpa deteksi, rekomendasi, atau bukti visual).
class AnalysisHistoryItem {
  final String batchName;
  final String dateLabel;
  final String species; // 'Arabica' | 'Robusta' | 'Mixed'
  final int qualityScore;
  final int visibleBeans;
  final Map<DefectClass, int> defectCounts;

  const AnalysisHistoryItem({
    required this.batchName,
    required this.dateLabel,
    required this.species,
    required this.qualityScore,
    required this.visibleBeans,
    required this.defectCounts,
  });

  int get healthyCount => defectCounts[DefectClass.healthy] ?? 0;

  /// Jumlah biji defect = total terlihat - Healthy.
  int get defectTotal => visibleBeans - healthyCount;

  /// Kelas defect (selain Healthy) yang jumlahnya > 0, urut dari terbanyak.
  List<DefectClass> get defectClasses {
    final entries = defectCounts.entries
        .where((e) => e.key != DefectClass.healthy && e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }

  /// Pemetaan skor ke grade indikatif (ambang mengikuti PRD bagian 8).
  IndicativeGrade get grade {
    if (qualityScore >= 85) return IndicativeGrade.specialty;
    if (qualityScore >= 75) return IndicativeGrade.premium;
    if (qualityScore >= 60) return IndicativeGrade.standard;
    if (qualityScore >= 40) return IndicativeGrade.belowStandard;
    return IndicativeGrade.offGrade;
  }
}

/// Nama pendek kelas defect untuk chip ringkas di kartu riwayat.
String defectShortLabel(DefectClass defectClass) {
  switch (defectClass) {
    case DefectClass.healthy:
      return 'Healthy';
    case DefectClass.broken:
      return 'Broken';
    case DefectClass.insectDamage:
      return 'Insect';
    case DefectClass.quaker:
      return 'Quaker';
    case DefectClass.scorched:
      return 'Scorched';
    case DefectClass.foreignMatter:
      return 'Foreign';
  }
}

/// Label grade untuk ditampilkan (mis. `GRADE INDIKATIF - SPECIALTY`).
String gradeDisplayLabel(IndicativeGrade grade) {
  switch (grade) {
    case IndicativeGrade.specialty:
      return 'GRADE INDIKATIF - SPECIALTY';
    case IndicativeGrade.premium:
      return 'GRADE INDIKATIF - PREMIUM';
    case IndicativeGrade.standard:
      return 'GRADE INDIKATIF - STANDARD';
    case IndicativeGrade.belowStandard:
      return 'GRADE INDIKATIF - BELOW STANDARD';
    case IndicativeGrade.offGrade:
      return 'GRADE INDIKATIF - OFF GRADE';
  }
}
