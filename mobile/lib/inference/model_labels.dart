/// Label kelas model visi + pemetaan ke enum aplikasi.
///
/// Label training memakai **snake_case**; enum DB/UI memakai **Title Case**
/// (`docs/ARCHITECTURE_ML.md` §3). Urutan list di sini WAJIB sama dengan urutan
/// kelas output model — jangan diubah tanpa mengecek ulang `argmax`.
library;

import '../shared/enums/defect_class.dart';

/// Species — 3 kelas (MobileNetV3-Small, `species_classifier.tflite`).
const List<String> kSpeciesLabels = <String>['arabica', 'liberika', 'robusta'];

/// Roast — 4 kelas (`roast_classifier.tflite`).
const List<String> kRoastLabels = <String>['green', 'light', 'medium', 'dark'];

/// Defect — 4 kelas gabungan (`defect_classifier.tflite`).
const List<String> kDefectLabels = <String>[
  'normal',
  'quaker',
  'broken',
  'severe',
];

/// Label training → label tampilan (Title Case).
const Map<String, String> kTrainingToDisplay = <String, String>{
  'arabica': 'Arabica',
  'liberika': 'Liberika',
  'robusta': 'Robusta',
  'mixed': 'Mixed',
  'green': 'Green',
  'light': 'Light',
  'medium': 'Medium',
  'dark': 'Dark',
  'normal': 'Normal',
  'quaker': 'Quaker',
  'broken': 'Broken',
  'severe': 'Severe',
};

/// Nilai kanonik untuk status roast yang tidak meyakinkan (§8).
///
/// Tidak disimpan ke kolom `analyses.roast` (CHECK hanya 4 kelas); UI memakai
/// `roast_confidence` untuk menampilkan label "uncertain".
const String kRoastUncertain = 'uncertain';

/// Species pengganti saat confidence < 0.70 (§8).
const String kSpeciesMixed = 'Mixed';

/// Ambang confidence kanonik (`ARCHITECTURE_ML.md` §8).
const double kSpeciesConfidenceThreshold = 0.70;
const double kRoastConfidenceThreshold = 0.45;

/// Bobot severity defect (`ARCHITECTURE_ML.md` §7/§9).
const Map<String, double> kDefectSeverityWeight = <String, double>{
  'normal': 0.0,
  'quaker': 0.7,
  'broken': 0.3,
  'severe': 1.0,
};

/// Index → label tampilan.
String displayLabelForIndex(List<String> labels, int index) {
  if (index < 0 || index >= labels.length) return '';
  return kTrainingToDisplay[labels[index]] ?? labels[index];
}

/// Index kelas defect → enum aplikasi.
DefectClass defectClassForIndex(int index) {
  switch (index) {
    case 0:
      return DefectClass.normal;
    case 1:
      return DefectClass.quaker;
    case 2:
      return DefectClass.broken;
    default:
      return DefectClass.severe;
  }
}
