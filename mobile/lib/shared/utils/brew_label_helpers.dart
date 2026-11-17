/// Helper label seduh **pure** (dipakai dua kali, Plan 3 §2):
/// resep KB ([BrewRecipe]) dan rekomendasi hasil analisis yang dibaca
/// dari SQLite (join `recommendations` + `brew_recipes`).
library;

/// Rasio seduh dihitung `water_volume_ml / dose_g` — tidak disimpan (D-10).
///
/// `'1:16'` bila bulat, `'1:15.5'` bila satu desimal, `'—'` bila
/// salah satu nilai hilang/tak valid.
String brewRatioLabel({double? doseG, int? waterVolumeMl}) {
  final dose = doseG;
  final water = waterVolumeMl;
  if (dose == null || dose <= 0 || water == null) return '—';
  final ratio = water / dose;
  final text = ratio == ratio.roundToDouble()
      ? ratio.toStringAsFixed(0)
      : ratio.toStringAsFixed(1);
  return '1:$text';
}

/// Waktu seduh dalam detik → label `mm:ss` (mis. 170 → `02:50`).
String formatBrewSeconds(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
}

/// Format gram dosis: `15` bila bulat, `15.5` bila ada desimal.
String formatDoseGrams(double? doseG) {
  final dose = doseG;
  if (dose == null) return '—';
  return dose == dose.roundToDouble()
      ? dose.toStringAsFixed(0)
      : dose.toStringAsFixed(1);
}
