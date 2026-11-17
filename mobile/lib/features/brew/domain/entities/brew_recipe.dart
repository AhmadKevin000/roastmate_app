/// Entitas fitur Brew (Resep Seduh & Detail Resep).
///
/// Bentuk field sengaja dibuat selaras dengan kolom `brew_methods` dan
/// `brew_recipes` pada `docs/DATABASE_SCHEMA.md`, sehingga saat data mock
/// diganti oleh `BrewingRepository` (SQLite) nanti, UI tidak perlu berubah.
library;

import 'brew_tool.dart';
import '../../../../shared/utils/brew_label_helpers.dart';

/// Fase langkah seduh (D-18): persiapan/alat vs langkah seduh.
enum BrewStepPhase { prep, brew }

/// Metadata metode seduh — deskriptif, tanpa parameter seduh (D-10).
class BrewMethod {
  final String methodId;
  final String methodName;
  final String methodType;
  final String subtitle;
  final String? imageAsset;
  final String description;
  final List<BrewTool> tools;

  const BrewMethod({
    required this.methodId,
    required this.methodName,
    required this.methodType,
    required this.subtitle,
    this.imageAsset,
    required this.description,
    this.tools = const [],
  });

  BrewMethod copyWith({
    String? methodId,
    String? methodName,
    String? methodType,
    String? subtitle,
    String? imageAsset,
    String? description,
    List<BrewTool>? tools,
  }) {
    return BrewMethod(
      methodId: methodId ?? this.methodId,
      methodName: methodName ?? this.methodName,
      methodType: methodType ?? this.methodType,
      subtitle: subtitle ?? this.subtitle,
      imageAsset: imageAsset ?? this.imageAsset,
      description: description ?? this.description,
      tools: tools ?? this.tools,
    );
  }
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

  /// Nama resep. Resep KB: `''` (nama tampil dari `brew_methods.method_name`);
  /// resep user: diisi dari form (Plan 4).
  final String name;

  /// ID metode KB. Resep KB: selalu terisi. Resep user: `null` bila metode
  /// "Lainnya" (di luar KB) — nama display diambil dari [methodName] (v6).
  final String? methodId;

  /// Nama display metode. Resep user: nama dari dropdown KB atau input
  /// "Lainnya"; resep KB: `''` (tampil dari entitas [BrewMethod]) (v6).
  final String methodName;

  /// Link video YouTube (preview cara seduh) — tampil di Detail Resep (v6).
  final String? videoUrl;

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
    this.name = '',
    this.methodId,
    this.methodName = '',
    this.videoUrl,
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
  String get ratioLabel =>
      brewRatioLabel(doseG: doseG, waterVolumeMl: waterVolumeMl);

  String get doseLabel => doseG == null ? '—' : '${doseG!.toStringAsFixed(1)} g';

  String get waterLabel =>
      waterVolumeMl == null ? '—' : '$waterVolumeMl ml';

  String get tempLabel =>
      temperatureC == null ? '—' : '$temperatureC°C';

  String get grindLabel => grindSize ?? '—';

  String get timeLabel =>
      brewingTimeS == null ? '—' : formatBrewSeconds(brewingTimeS!);
}
