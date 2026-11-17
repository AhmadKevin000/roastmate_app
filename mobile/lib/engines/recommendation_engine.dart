import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../shared/models/analysis_result.dart';
import '../features/analysis/data/sources/analysis_repository.dart';

/// Hasil dari Recommendation Engine.
class RecommendationEngineResult {
  /// Rekomendasi utama (null bila green bean atau tidak ada resep cocok).
  final BrewRecommendation? recommendation;

  /// Referensi untuk disimpan ke SQLite.
  final RecommendationRef? ref;

  /// Metode alternatif.
  final List<AlternativeMethod> alternatives;

  const RecommendationEngineResult({
    this.recommendation,
    this.ref,
    required this.alternatives,
  });
}

/// Engine rekomendasi seduh berbasis Knowledge Base (SQLite).
///
/// Mencari resep terbaik dari `brew_recipes` berdasarkan species + roast +
/// quality_profile. Semua parameter seduh berasal dari KB, bukan dari ML.
class RecommendationEngine {
  const RecommendationEngine(this._db);

  final Database _db;

  /// Mencari rekomendasi utama dan alternatif dari KB.
  ///
  /// Mengembalikan [RecommendationEngineResult] dengan recommendation = null
  /// bila roast == 'Green' (biji mentah tidak direkomendasikan untuk diseduh).
  Future<RecommendationEngineResult> resolve({
    required String species,
    required String roast,
    required QualityProfile qualityProfile,
  }) async {
    // Green bean — tidak ada rekomendasi seduh
    if (roast.toLowerCase() == 'green') {
      return const RecommendationEngineResult(alternatives: []);
    }

    final profileStr = _profileToString(qualityProfile);

    // Cari resep terbaik yang cocok (prioritas: exact match)
    final primaryRecipe = await _findBestRecipe(
      species: species,
      roast: roast,
      qualityProfile: profileStr,
    );

    BrewRecommendation? recommendation;
    RecommendationRef? ref;

    if (primaryRecipe != null) {
      recommendation = _buildRecommendation(primaryRecipe, qualityProfile);
      ref = RecommendationRef(
        methodId: primaryRecipe['method_id'] as String,
        recipeId: primaryRecipe['recipe_id'] as String?,
        reason: recommendation.reasonText,
      );
    } else {
      debugPrint(
        '[RecommendationEngine] Tidak ada resep untuk '
        '$species/$roast/$profileStr — pakai fallback',
      );
      final fallback = await _findFallback(species: species, roast: roast);
      if (fallback != null) {
        recommendation = _buildRecommendation(fallback, qualityProfile);
        ref = RecommendationRef(
          methodId: fallback['method_id'] as String,
          recipeId: fallback['recipe_id'] as String?,
          reason: recommendation.reasonText,
        );
      }
    }

    // Ambil 2 metode alternatif dari method_id yang berbeda
    final primaryMethodId = ref?.methodId;
    final alternatives = await _buildAlternatives(
      species: species,
      roast: roast,
      excludeMethodId: primaryMethodId,
    );

    return RecommendationEngineResult(
      recommendation: recommendation,
      ref: ref,
      alternatives: alternatives,
    );
  }

  /// Mencari resep terbaik dengan fallback bertahap:
  ///   1. Exact: species + roast + quality_profile + is_default
  ///   2. Relax quality_profile
  ///   3. Relax species → 'Mixed' or any
  Future<Map<String, Object?>?> _findBestRecipe({
    required String species,
    required String roast,
    required String qualityProfile,
  }) async {
    // Tahap 1: exact match
    var rows = await _queryRecipes(
      species: species,
      roast: roast,
      qualityProfile: qualityProfile,
      isDefault: true,
    );
    if (rows.isNotEmpty) return rows.first;

    // Tahap 2: relax is_default
    rows = await _queryRecipes(
      species: species,
      roast: roast,
      qualityProfile: qualityProfile,
    );
    if (rows.isNotEmpty) return rows.first;

    // Tahap 3: relax quality_profile
    rows = await _queryRecipes(species: species, roast: roast);
    if (rows.isNotEmpty) return rows.first;

    // Tahap 4: fallback ke Mixed
    if (species != 'Mixed') {
      rows = await _queryRecipes(species: 'Mixed', roast: roast);
      if (rows.isNotEmpty) return rows.first;
    }

    return null;
  }

  Future<Map<String, Object?>?> _findFallback({
    required String species,
    required String roast,
  }) async {
    // Last resort: ambil resep mana saja yang roastnya cocok
    final rows = await _db.query(
      'brew_recipes',
      where: 'roast_context = ?',
      whereArgs: [roast],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first;

    // Ultra-last-resort: ambil resep pertama
    final all = await _db.query('brew_recipes', limit: 1);
    return all.isNotEmpty ? all.first : null;
  }

  Future<List<Map<String, Object?>>> _queryRecipes({
    required String species,
    required String roast,
    String? qualityProfile,
    bool? isDefault,
  }) async {
    final conditions = <String>['species = ?', 'roast_context = ?'];
    final args = <Object?>[species, roast];

    if (qualityProfile != null) {
      conditions.add('quality_profile = ?');
      args.add(qualityProfile);
    }
    if (isDefault != null) {
      conditions.add('is_default = ?');
      args.add(isDefault ? 1 : 0);
    }

    return _db.query(
      'brew_recipes',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'is_default DESC',
      limit: 1,
    );
  }

  /// Membangun [BrewRecommendation] dari row SQLite.
  BrewRecommendation _buildRecommendation(
    Map<String, Object?> recipe,
    QualityProfile profile,
  ) {
    final methodName = recipe['method_id'] as String? ?? 'M001';
    final doseG = (recipe['dose_g'] as num?)?.toDouble() ?? 15;
    final waterMl = (recipe['water_volume_ml'] as num?)?.toDouble() ?? 225;
    final ratio = (waterMl / doseG).round();
    final tempC = (recipe['temperature_c'] as num?)?.toInt() ?? 90;
    final brewingS = (recipe['brewing_time_s'] as num?)?.toInt() ?? 180;
    final grindSize = recipe['grind_size'] as String? ?? 'Medium';
    final species = recipe['species'] as String? ?? 'Mixed';
    final roastCtx = recipe['roast_context'] as String? ?? 'Medium';
    final notes = recipe['notes'] as String? ?? '';

    final methodTitle = _buildMethodTitle(methodName, roastCtx, species);
    final reasonText = _buildReasonText(
      methodId: methodName,
      species: species,
      roast: roastCtx,
      profile: profile,
      notes: notes,
    );

    final timeMin = brewingS ~/ 60;
    final timeSec = (brewingS % 60).toString().padLeft(2, '0');
    final timeLabel = '$timeMin:$timeSec';

    final ratioSub = '${doseG.round()}g : ${waterMl.round()}ml air';
    final tempSub = _tempRange(tempC);
    final grindSub = _grindClickGuide(grindSize);
    final timeSub = _timeSub(methodName);

    return BrewRecommendation(
      methodTitle: methodTitle,
      reasonText: reasonText,
      ratio: '1:$ratio',
      ratioSub: ratioSub,
      tempC: '$tempC°C',
      tempCSub: tempSub,
      grind: grindSize,
      grindSub: grindSub,
      targetTime: timeLabel,
      targetTimeSub: timeSub,
    );
  }

  String _buildMethodTitle(String methodId, String roast, String species) {
    final methodName = _methodDisplayName(methodId);
    final roastLabel = _shortRoastLabel(roast);
    final speciesLabel = species == 'Mixed' ? 'Blend' : species;
    return '$methodName — $speciesLabel $roastLabel';
  }

  String _buildReasonText({
    required String methodId,
    required String species,
    required String roast,
    required QualityProfile profile,
    required String notes,
  }) {
    final methodName = _methodDisplayName(methodId);
    final profileLabel = _profileLabel(profile);
    final roastLabel = _shortRoastLabel(roast);
    final speciesLabel = species == 'Mixed' ? 'campuran' : species;

    if (notes.isNotEmpty) {
      return 'Berdasarkan profil $profileLabel $speciesLabel $roastLabel, '
          '$methodName dipilih karena: $notes';
    }
    return 'Berdasarkan profil kualitas $profileLabel dan karakteristik '
        '$speciesLabel $roastLabel, $methodName memberikan ekstraksi optimal.';
  }

  /// Membangun 2 metode alternatif dari method_id yang berbeda.
  Future<List<AlternativeMethod>> _buildAlternatives({
    required String species,
    required String roast,
    String? excludeMethodId,
  }) async {
    final allMethods = await _db.query('brew_methods');
    final alternatives = <AlternativeMethod>[];

    for (final method in allMethods) {
      if (alternatives.length >= 2) break;
      final methodId = method['method_id'] as String;
      if (methodId == excludeMethodId) continue;

      // Cari resep untuk metode ini
      final recipes = await _queryRecipes(species: species, roast: roast);
      Map<String, Object?>? recipe;

      if (recipes.isNotEmpty) {
        recipe = recipes.first;
      } else {
        // Fallback: resep mana saja dari method ini
        final any = await _db.query(
          'brew_recipes',
          where: 'method_id = ?',
          whereArgs: [methodId],
          limit: 1,
        );
        recipe = any.isNotEmpty ? any.first : null;
      }

      if (recipe == null) continue;

      final doseG = (recipe['dose_g'] as num?)?.toDouble() ?? 15;
      final waterMl = (recipe['water_volume_ml'] as num?)?.toDouble() ?? 225;
      final ratio = (waterMl / doseG).round();
      final tempC = (recipe['temperature_c'] as num?)?.toInt() ?? 90;
      final brewingS = (recipe['brewing_time_s'] as num?)?.toInt() ?? 180;
      final grindSize = recipe['grind_size'] as String? ?? 'Medium';
      final timeMin = brewingS ~/ 60;
      final timeSec = (brewingS % 60).toString().padLeft(2, '0');
      final methodName = method['method_name'] as String? ?? methodId;
      final description = method['description'] as String? ?? '';

      alternatives.add(AlternativeMethod(
        title: methodName,
        description: 'Rasio 1:$ratio · $timeMin:$timeSec · $description',
        ratio: '1:$ratio',
        ratioSub: '${doseG.round()}g : ${waterMl.round()}ml air',
        tempC: '$tempC°C',
        tempCSub: _tempRange(tempC),
        grind: grindSize,
        grindSub: _grindClickGuide(grindSize),
        targetTime: '$timeMin:$timeSec',
        targetTimeSub: _timeSub(methodId),
      ));
    }

    return alternatives;
  }

  // -----------------------------------------------------------------------
  // Helper formatter
  // -----------------------------------------------------------------------

  String _methodDisplayName(String methodId) {
    switch (methodId) {
      case 'M001':
        return 'Pour Over (V60)';
      case 'M002':
        return 'French Press';
      case 'M003':
        return 'Kopi Tubruk';
      default:
        return methodId;
    }
  }

  String _shortRoastLabel(String roast) {
    switch (roast.toLowerCase()) {
      case 'light':
        return 'Light Roast';
      case 'medium':
        return 'Medium Roast';
      case 'dark':
        return 'Dark Roast';
      default:
        return roast;
    }
  }

  String _profileLabel(QualityProfile profile) {
    switch (profile) {
      case QualityProfile.high:
        return 'specialty/premium';
      case QualityProfile.medium:
        return 'standar';
      case QualityProfile.low:
        return 'di bawah standar';
    }
  }

  String _tempRange(int tempC) {
    return '${tempC - 2}–${tempC + 2}°C optimal';
  }

  String _grindClickGuide(String grindSize) {
    switch (grindSize.toLowerCase()) {
      case 'fine':
        return '8–10 klik C2/Timemore';
      case 'medium-fine':
        return '14–16 klik C2/Timemore';
      case 'medium':
        return '17–19 klik C2/Timemore';
      case 'medium-coarse':
        return '20–22 klik C2/Timemore';
      case 'coarse':
        return '22–24 klik C2/Timemore';
      default:
        return grindSize;
    }
  }

  String _timeSub(String methodId) {
    switch (methodId) {
      case 'M001':
        return '4 tahap tuang air';
      case 'M002':
        return 'rendam + press plunger';
      case 'M003':
        return 'tunggu ampas mengendap';
      default:
        return 'sesuai metode';
    }
  }

  String _profileToString(QualityProfile profile) {
    switch (profile) {
      case QualityProfile.high:
        return 'High';
      case QualityProfile.medium:
        return 'Medium';
      case QualityProfile.low:
        return 'Low';
    }
  }
}

