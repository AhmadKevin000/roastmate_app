/// Entitas fitur Brew (Resep Seduh & Detail Resep).
///
/// Bentuk field sengaja dibuat selaras dengan kolom `brew_methods` dan
/// `brew_recipes` pada `docs/DATABASE_SCHEMA.md`, sehingga saat data mock
/// diganti oleh `BrewingRepository` (SQLite) nanti, UI tidak perlu berubah.
library;

/// Fase langkah seduh (D-18): persiapan/alat vs langkah seduh.
enum BrewStepPhase { prep, brew }

/// Metadata metode seduh — deskriptif, tanpa parameter seduh (D-10).
class BrewMethod {
  final String methodId;
  final String methodName;
  final String methodType;
  final String subtitle;
  final String description;

  const BrewMethod({
    required this.methodId,
    required this.methodName,
    required this.methodType,
    required this.subtitle,
    required this.description,
  });
}

/// Satu langkah seduh (item kolom JSON `steps`).
///
/// `targetTime` adalah **label waktu statis** (mis. `00:00 – 00:45`),
/// bukan timer berjalan (D-01).
class BrewStep {
  final int stepNo;
  final BrewStepPhase phase;
  final String title;
  final String description;
  final String? targetTime;
  final String? callout;

  const BrewStep({
    required this.stepNo,
    required this.phase,
    required this.title,
    required this.description,
    this.targetTime,
    this.callout,
  });
}

/// Resep seduh — pemilik seluruh parameter seduh (D-10).
class BrewRecipe {
  final String recipeId;
  final String methodId;
  final String species;
  final String qualityProfile;
  final String roastContext;
  final double? doseG;
  final int? waterVolumeMl;
  final String? grindSize;
  final int? temperatureC;
  final int? brewingTimeS;
  final String source;
  final bool isDefault;
  final List<BrewStep> steps;
  final String? notes;

  /// Deskriptor rasa singkat untuk hero Detail Resep (presentasi).
  final String flavorProfile;

  /// Label jumlah tahap penuangan (presentasi).
  final String pourLabel;

  const BrewRecipe({
    required this.recipeId,
    required this.methodId,
    required this.species,
    required this.qualityProfile,
    required this.roastContext,
    this.doseG,
    this.waterVolumeMl,
    this.grindSize,
    this.temperatureC,
    this.brewingTimeS,
    required this.source,
    this.isDefault = false,
    this.steps = const [],
    this.notes,
    this.flavorProfile = '',
    this.pourLabel = '',
  });

  List<BrewStep> get prepSteps =>
      steps.where((s) => s.phase == BrewStepPhase.prep).toList();

  List<BrewStep> get brewSteps =>
      steps.where((s) => s.phase == BrewStepPhase.brew).toList();

  /// Rasio **dihitung** `water_volume_ml / dose_g` — tidak disimpan (D-10).
  String get ratioLabel {
    final dose = doseG;
    final water = waterVolumeMl;
    if (dose == null || dose <= 0 || water == null) return '—';
    final ratio = water / dose;
    final text = ratio == ratio.roundToDouble()
        ? ratio.toStringAsFixed(0)
        : ratio.toStringAsFixed(1);
    return '1:$text';
  }

  String get doseLabel => doseG == null ? '—' : '${doseG!.toStringAsFixed(1)} g';

  String get waterLabel =>
      waterVolumeMl == null ? '—' : '$waterVolumeMl ml';

  String get tempLabel =>
      temperatureC == null ? '—' : '$temperatureC°C';

  String get grindLabel => grindSize ?? '—';

  String get timeLabel =>
      brewingTimeS == null ? '—' : _formatSeconds(brewingTimeS!);

  static String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
  }
}
