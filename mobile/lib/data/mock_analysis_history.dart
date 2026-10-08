import 'dart:ui';

import '../domain/analysis_history_item.dart';
import '../domain/inspection_result.dart';

/// Data dummy riwayat analisis untuk mengembangkan UI (belum tersambung SQLite).
///
/// Tiap item membawa [InspectionResult] lengkap supaya kartu riwayat bisa
/// membuka layar Detail Inspeksi. Mengikuti mockup `UI/Riwayat Analisis.png`.
final List<AnalysisHistoryItem> mockAnalysisHistory = [
  AnalysisHistoryItem(
    dateLabel: '12 Mar 2025, 10:24 WIB',
    detail: InspectionResult(
      batchLabel: 'Batch #042',
      batchName: 'Mandheling Honey Anaerob',
      analyzedAgo: 'Dipindai 12 menit yang lalu',
      qualityScore: 86,
      visibleBeans: 28,
      defectCounts: const {
        DefectClass.healthy: 26,
        DefectClass.broken: 1,
        DefectClass.quaker: 1,
        DefectClass.insectDamage: 0,
        DefectClass.scorched: 0,
        DefectClass.foreignMatter: 0,
      },
      species: 'Arabica',
      roast: 'Light',
      summaryText:
          'Sebagian besar biji memiliki kematangan merata dengan defect fisik minimal. Sangat potensial untuk profil seduh pour-over beraroma buah tropis.',
      recommendation: BrewRecommendation(
        methodTitle: 'Pour Over (V60) - Clean & Bright',
        reasonText:
            'Berdasarkan skor Specialty 86/100 dengan tingkat defect rendah dan profil fruity menonjol, metode drip V60 mengoptimalkan clarity keasaman bersih tanpa mengekstrak astringency.',
        ratio: '1:15',
        ratioSub: '15g : 225ml air',
        tempC: '92°C',
        tempCSub: '90-94°C optimal',
        grind: 'Medium-Fine',
        grindSub: '14-16 klik C2/Timemore',
        targetTime: '02:45',
        targetTimeSub: '4 tahap tuang air',
      ),
      alternatives: [
        AlternativeMethod(
          title: 'Aeropress (Inverted)',
          description: 'Rasio 1:14 · 02:00 · Body lebih tebal & manis',
        ),
        AlternativeMethod(
          title: 'French Press / Immersion',
          description: 'Rasio 1:14 · 04:00 · Keasaman lebih lembut & round',
        ),
      ],
      detections: [
        _det(DefectClass.healthy, 0.10, 0.10, 0.15, 0.10, 0.95),
        _det(DefectClass.healthy, 0.30, 0.20, 0.12, 0.12, 0.90),
        _det(DefectClass.healthy, 0.60, 0.12, 0.15, 0.08, 0.88),
        _det(DefectClass.healthy, 0.78, 0.32, 0.12, 0.15, 0.92),
        _det(DefectClass.broken, 0.55, 0.65, 0.15, 0.12, 0.88),
        _det(DefectClass.quaker, 0.20, 0.60, 0.16, 0.15, 0.82),
      ],
      modelVersion: 'Model CV v2.4',
    ),
  ),
  AnalysisHistoryItem(
    dateLabel: '11 Mar 2025, 14:10 WIB',
    detail: InspectionResult(
      batchLabel: 'Batch #041',
      batchName: 'Gayo Washed Grade 1',
      analyzedAgo: 'Dipindai kemarin',
      qualityScore: 90,
      visibleBeans: 34,
      defectCounts: const {
        DefectClass.healthy: 33,
        DefectClass.broken: 1,
        DefectClass.quaker: 0,
        DefectClass.insectDamage: 0,
        DefectClass.scorched: 0,
        DefectClass.foreignMatter: 0,
      },
      species: 'Arabica',
      roast: 'Light',
      summaryText:
          'Batch sangat bersih dengan keseragaman bentuk dan warna tinggi. Ideal untuk profil seduh bright dan tea-like.',
      recommendation: BrewRecommendation(
        methodTitle: 'Pour Over (V60) - Tea Like',
        reasonText:
            'Defect sangat rendah dan warna merata; V60 menjaga kejernihan rasa serta kompleksitas floral.',
        ratio: '1:16',
        ratioSub: '15g : 240ml air',
        tempC: '93°C',
        tempCSub: '92-94°C optimal',
        grind: 'Medium',
        grindSub: '16-18 klik C2/Timemore',
        targetTime: '03:00',
        targetTimeSub: '3 tahap tuang air',
      ),
      alternatives: [
        AlternativeMethod(
          title: 'Chemex',
          description: 'Rasio 1:16 · 03:30 · Body ringan & bersih',
        ),
      ],
      detections: [
        _det(DefectClass.healthy, 0.12, 0.14, 0.14, 0.11, 0.94),
        _det(DefectClass.healthy, 0.35, 0.22, 0.13, 0.12, 0.91),
        _det(DefectClass.healthy, 0.62, 0.10, 0.15, 0.09, 0.89),
        _det(DefectClass.broken, 0.72, 0.66, 0.14, 0.11, 0.86),
      ],
      modelVersion: 'Model CV v2.4',
    ),
  ),
  AnalysisHistoryItem(
    dateLabel: '10 Mar 2025, 16:15 WIB',
    detail: InspectionResult(
      batchLabel: 'Batch #040',
      batchName: 'Temanggung Fine Robusta',
      analyzedAgo: 'Dipindai 2 hari lalu',
      qualityScore: 82,
      visibleBeans: 30,
      defectCounts: const {
        DefectClass.healthy: 26,
        DefectClass.broken: 0,
        DefectClass.quaker: 0,
        DefectClass.insectDamage: 2,
        DefectClass.scorched: 2,
        DefectClass.foreignMatter: 0,
      },
      species: 'Robusta',
      roast: 'Dark',
      summaryText:
          'Robusta dengan body tebal dan sedikit defect gosong. Cocok untuk seduhan bertekstur kuat atau basis espresso.',
      recommendation: BrewRecommendation(
        methodTitle: 'Moka Pot - Bold & Syrupy',
        reasonText:
            'Profil robusta dark roast menonjolkan body tebal dan pahit cokelat; moka pot mengekstrak tekstur sirup.',
        ratio: '1:12',
        ratioSub: '18g : 216ml air',
        tempC: '95°C',
        tempCSub: '95-96°C optimal',
        grind: 'Fine',
        grindSub: '8-10 klik C2/Timemore',
        targetTime: '04:00',
        targetTimeSub: 'panaskan hingga mendidih',
      ),
      alternatives: [
        AlternativeMethod(
          title: 'French Press / Immersion',
          description: 'Rasio 1:13 · 04:00 · Body penuh & creamy',
        ),
      ],
      detections: [
        _det(DefectClass.healthy, 0.14, 0.12, 0.15, 0.12, 0.93),
        _det(DefectClass.healthy, 0.40, 0.24, 0.13, 0.12, 0.90),
        _det(DefectClass.insectDamage, 0.62, 0.15, 0.14, 0.12, 0.85),
        _det(DefectClass.scorched, 0.30, 0.62, 0.15, 0.13, 0.84),
      ],
      modelVersion: 'Model CV v2.4',
    ),
  ),
  AnalysisHistoryItem(
    dateLabel: '08 Mar 2025, 09:30 WIB',
    detail: InspectionResult(
      batchLabel: 'Batch #039',
      batchName: 'Kintamani Natural',
      analyzedAgo: 'Dipindai 4 hari lalu',
      qualityScore: 76,
      visibleBeans: 25,
      defectCounts: const {
        DefectClass.healthy: 19,
        DefectClass.broken: 2,
        DefectClass.quaker: 3,
        DefectClass.insectDamage: 0,
        DefectClass.scorched: 0,
        DefectClass.foreignMatter: 1,
      },
      species: 'Arabica',
      roast: 'Medium',
      summaryText:
          'Defect sedang didominasi quaker dan patahan. Masih layak untuk seduhan harian dengan profil rasa seimbang.',
      recommendation: BrewRecommendation(
        methodTitle: 'Aeropress - Balanced',
        reasonText:
            'Defect sedang membuat ekstraksi kurang merata; Aeropress memberi kontrol tekanan untuk hasil seimbang.',
        ratio: '1:14',
        ratioSub: '16g : 224ml air',
        tempC: '90°C',
        tempCSub: '88-92°C optimal',
        grind: 'Medium-Fine',
        grindSub: '12-14 klik C2/Timemore',
        targetTime: '02:00',
        targetTimeSub: '1 menit seduh + press',
      ),
      alternatives: [
        AlternativeMethod(
          title: 'Pour Over (V60)',
          description: 'Rasio 1:15 · 02:45 · Kejernihan lebih tinggi',
        ),
      ],
      detections: [
        _det(DefectClass.healthy, 0.15, 0.15, 0.14, 0.12, 0.90),
        _det(DefectClass.quaker, 0.38, 0.20, 0.15, 0.13, 0.83),
        _det(DefectClass.broken, 0.60, 0.18, 0.13, 0.11, 0.87),
        _det(DefectClass.foreignMatter, 0.44, 0.64, 0.12, 0.11, 0.80),
      ],
      modelVersion: 'Model CV v2.4',
    ),
  ),
  AnalysisHistoryItem(
    dateLabel: '05 Mar 2025, 11:05 WIB',
    detail: InspectionResult(
      batchLabel: 'Batch #038',
      batchName: 'Sidikalang Blend House',
      analyzedAgo: 'Dipindai 1 minggu lalu',
      qualityScore: 68,
      visibleBeans: 32,
      defectCounts: const {
        DefectClass.healthy: 26,
        DefectClass.broken: 3,
        DefectClass.quaker: 2,
        DefectClass.insectDamage: 0,
        DefectClass.scorched: 1,
        DefectClass.foreignMatter: 0,
      },
      species: 'Mixed',
      roast: 'Medium',
      summaryText:
          'Batch campuran Arabica-Robusta dengan defect sedang. Profil rasa seimbang, cocok untuk seduhan harian bergaya tubruk.',
      recommendation: BrewRecommendation(
        methodTitle: 'Kopi Tubruk - Daily',
        reasonText:
            'Campuran Arabica-Robusta menghasilkan rasa seimbang; metode tubruk sederhana menonjolkan body dan aroma.',
        ratio: '1:10',
        ratioSub: '12g : 120ml air',
        tempC: '96°C',
        tempCSub: '95-98°C optimal',
        grind: 'Medium-Coarse',
        grindSub: '20-22 klik C2/Timemore',
        targetTime: '04:00',
        targetTimeSub: 'seduh + endapkan',
      ),
      alternatives: [
        AlternativeMethod(
          title: 'French Press / Immersion',
          description: 'Rasio 1:12 · 04:00 · Tekstur lebih tebal',
        ),
      ],
      detections: [
        _det(DefectClass.healthy, 0.16, 0.14, 0.14, 0.12, 0.89),
        _det(DefectClass.broken, 0.40, 0.22, 0.13, 0.11, 0.86),
        _det(DefectClass.quaker, 0.62, 0.16, 0.14, 0.12, 0.82),
        _det(DefectClass.scorched, 0.34, 0.62, 0.15, 0.13, 0.81),
      ],
      modelVersion: 'Model CV v2.4',
    ),
  ),
];

BeanDetection _det(
  DefectClass defectClass,
  double left,
  double top,
  double width,
  double height,
  double confidence,
) {
  return BeanDetection(
    classLabel: defectClass,
    normalizedRect: Rect.fromLTWH(left, top, width, height),
    confidence: confidence,
  );
}
