import 'dart:ui';
import '../domain/inspection_result.dart';

final mockInspectionResult = InspectionResult(
  batchLabel: "Batch #042",
  batchName: "Mandheling Honey",
  analyzedAgo: "Dipindai 12 menit yang lalu",
  qualityScore: 86,
  visibleBeans: 28,
  defectCounts: {
    DefectClass.healthy: 24,
    DefectClass.broken: 2,
    DefectClass.quaker: 1,
    DefectClass.insectDamage: 1,
    DefectClass.scorched: 0,
    DefectClass.foreignMatter: 0,
  },
  species: "Arabica",
  roast: "Light",
  summaryText: "Sebagian besar biji memiliki kematangan merata dengan defect fisik minimal. Sangat potensial untuk profil seduh pour-over beraroma buah tropis.",
  recommendation: BrewRecommendation(
    methodTitle: "Pour Over (V60) — Clean & Bright",
    reasonText: "Berdasarkan skor Specialty 86/100 dengan tingkat defect rendah (14.3%) dan profil fruity menonjol, metode drip V60 mengoptimalkan clarity keasaman bersih dan aroma buah tropis tanpa mengekstrak astringency.",
    ratio: "1:15",
    ratioSub: "15g : 225ml air",
    tempC: "92°C",
    tempCSub: "90–94°C optimal",
    grind: "Medium-Fine",
    grindSub: "14–16 klik C2/Timemore",
    targetTime: "02:45",
    targetTimeSub: "4 tahap tuang air",
  ),
  alternatives: [
    AlternativeMethod(
      title: "Aeropress (Inverted)",
      description: "Rasio 1:14 · 02:00 · Body lebih tebal & manis",
    ),
    AlternativeMethod(
      title: "French Press / Immersion",
      description: "Rasio 1:14 · 04:00 · Keasaman lebih lembut & round",
    ),
  ],
  detections: [
    BeanDetection(classLabel: DefectClass.healthy, normalizedRect: const Rect.fromLTWH(0.1, 0.1, 0.15, 0.1), confidence: 0.95),
    BeanDetection(classLabel: DefectClass.healthy, normalizedRect: const Rect.fromLTWH(0.3, 0.2, 0.12, 0.12), confidence: 0.90),
    BeanDetection(classLabel: DefectClass.healthy, normalizedRect: const Rect.fromLTWH(0.6, 0.1, 0.15, 0.08), confidence: 0.88),
    BeanDetection(classLabel: DefectClass.healthy, normalizedRect: const Rect.fromLTWH(0.8, 0.3, 0.12, 0.15), confidence: 0.92),
    BeanDetection(classLabel: DefectClass.insectDamage, normalizedRect: const Rect.fromLTWH(0.40, 0.25, 0.15, 0.14), confidence: 0.85),
    BeanDetection(classLabel: DefectClass.quaker, normalizedRect: const Rect.fromLTWH(0.20, 0.60, 0.16, 0.15), confidence: 0.82),
    BeanDetection(classLabel: DefectClass.broken, normalizedRect: const Rect.fromLTWH(0.55, 0.65, 0.15, 0.12), confidence: 0.88),
    BeanDetection(classLabel: DefectClass.broken, normalizedRect: const Rect.fromLTWH(0.75, 0.7, 0.14, 0.11), confidence: 0.80),
  ],
  modelVersion: "Model CV v2.4",
);
