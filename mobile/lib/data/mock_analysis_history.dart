import '../domain/analysis_history_item.dart';
import '../domain/inspection_result.dart';

/// Data dummy riwayat analisis untuk mengembangkan UI (belum tersambung SQLite).
///
/// Mengikuti mockup `UI/Riwayat Analisis.png`.
final List<AnalysisHistoryItem> mockAnalysisHistory = [
  const AnalysisHistoryItem(
    batchName: 'Mandheling Honey Anaerob',
    dateLabel: '12 Mar 2025, 10:24 WIB',
    species: 'Arabica',
    qualityScore: 86,
    visibleBeans: 28,
    defectCounts: {
      DefectClass.healthy: 26,
      DefectClass.broken: 1,
      DefectClass.quaker: 1,
      DefectClass.insectDamage: 0,
      DefectClass.scorched: 0,
      DefectClass.foreignMatter: 0,
    },
  ),
  const AnalysisHistoryItem(
    batchName: 'Gayo Washed Grade 1',
    dateLabel: '11 Mar 2025, 14:10 WIB',
    species: 'Arabica',
    qualityScore: 90,
    visibleBeans: 34,
    defectCounts: {
      DefectClass.healthy: 33,
      DefectClass.broken: 1,
      DefectClass.quaker: 0,
      DefectClass.insectDamage: 0,
      DefectClass.scorched: 0,
      DefectClass.foreignMatter: 0,
    },
  ),
  const AnalysisHistoryItem(
    batchName: 'Temanggung Fine Robusta',
    dateLabel: '10 Mar 2025, 16:15 WIB',
    species: 'Robusta',
    qualityScore: 82,
    visibleBeans: 30,
    defectCounts: {
      DefectClass.healthy: 26,
      DefectClass.broken: 0,
      DefectClass.quaker: 0,
      DefectClass.insectDamage: 2,
      DefectClass.scorched: 2,
      DefectClass.foreignMatter: 0,
    },
  ),
  const AnalysisHistoryItem(
    batchName: 'Kintamani Natural',
    dateLabel: '08 Mar 2025, 09:30 WIB',
    species: 'Arabica',
    qualityScore: 76,
    visibleBeans: 25,
    defectCounts: {
      DefectClass.healthy: 19,
      DefectClass.broken: 2,
      DefectClass.quaker: 3,
      DefectClass.insectDamage: 0,
      DefectClass.scorched: 0,
      DefectClass.foreignMatter: 1,
    },
  ),
];
