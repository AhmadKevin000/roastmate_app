import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/brew_recipe.dart';
import '../../domain/entities/brew_tool.dart';
import '../../domain/repositories/brewing_repository.dart';

class BrewingRepositoryImpl implements BrewingRepository {
  final AppDatabase _dbProvider;
  final Database? _directDb;

  BrewingRepositoryImpl({AppDatabase? dbProvider, Database? database})
      : _dbProvider = dbProvider ?? AppDatabase.instance,
        _directDb = database;

  Future<Database> get _db async => _directDb ?? await _dbProvider.database;

  @override
  Future<List<BrewMethod>> getMethods() async {
    final db = await _db;
    final methodRows = await db.query(
      'brew_methods',
      orderBy: 'method_id ASC',
    );

    if (methodRows.isEmpty) return [];

    final List<BrewMethod> result = [];
    for (final row in methodRows) {
      final methodId = row['method_id'] as String;
      final tools = await _getToolsForMethod(db, methodId);
      result.add(_parseMethod(row, tools));
    }
    return result;
  }

  @override
  Future<BrewMethod?> getMethodById(String methodId) async {
    final db = await _db;
    final rows = await db.query(
      'brew_methods',
      where: 'method_id = ?',
      whereArgs: [methodId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final tools = await _getToolsForMethod(db, methodId);
    return _parseMethod(rows.first, tools);
  }

  @override
  Future<List<BrewRecipe>> getRecipesForMethod(String methodId) async {
    final db = await _db;
    final rows = await db.query(
      'brew_recipes',
      where: 'method_id = ?',
      whereArgs: [methodId],
      orderBy: 'is_default DESC, recipe_id ASC',
    );

    return rows.map(_parseRecipe).toList();
  }

  @override
  Future<BrewRecipe?> getRecipeById(String recipeId) async {
    final db = await _db;
    final rows = await db.query(
      'brew_recipes',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return _parseRecipe(rows.first);
  }

  @override
  Future<BrewRecipe?> getDefaultRecipe(String methodId) async {
    final db = await _db;
    final rows = await db.query(
      'brew_recipes',
      where: 'method_id = ? AND is_default = 1',
      whereArgs: [methodId],
      limit: 1,
    );

    if (rows.isNotEmpty) return _parseRecipe(rows.first);

    // Fallback ambil resep pertama jika tidak ada yang marked default
    final fallback = await db.query(
      'brew_recipes',
      where: 'method_id = ?',
      whereArgs: [methodId],
      limit: 1,
    );

    if (fallback.isEmpty) return null;
    return _parseRecipe(fallback.first);
  }

  @override
  Future<BrewRecipe?> findDefaultRecipe({
    required String species,
    required String roastContext,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'brew_recipes',
      where: 'species = ? AND roast_context = ? AND is_default = 1',
      whereArgs: [species, roastContext],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return _parseRecipe(rows.first);
  }

  @override
  Future<List<BrewTool>> getAllTools() async {
    final db = await _db;
    final rows = await db.query(
      'brew_tools',
      orderBy: 'tool_id ASC',
    );
    return rows.map((r) => BrewTool.fromMap(r)).toList();
  }

  @override
  Future<BrewRecipe?> getUserRecipeById(String recipeId) async {
    final db = await _db;
    final rows = await db.query(
      'user_brew_recipes',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _parseUserRecipe(rows.first);
  }

  @override
  Future<List<BrewRecipe>> getUserRecipes() async {
    final db = await _db;
    final rows = await db.query(
      'user_brew_recipes',
      orderBy: 'created_at DESC',
    );
    return rows.map(_parseUserRecipe).toList();
  }

  @override
  Future<void> insertUserRecipe(BrewRecipe recipe) async {
    final db = await _db;
    // Validasi ringan: bila metode KB dipilih, pastikan ada (FK juga menolak).
    // `methodId` null = metode "Lainnya" (di luar KB) — sah (v6).
    final methodId = recipe.methodId;
    if (methodId != null) {
      final methodRows = await db.query(
        'brew_methods',
        where: 'method_id = ?',
        whereArgs: [methodId],
        limit: 1,
      );
      if (methodRows.isEmpty) {
        throw Exception('Metode $methodId tidak ada di knowledge base');
      }
    }
    await db.insert(
      'user_brew_recipes',
      <String, Object?>{
        'recipe_id': 'U${DateTime.now().microsecondsSinceEpoch}',
        'name': recipe.name,
        'method_id': methodId,
        'method_name': recipe.methodName,
        'species': recipe.species,
        'quality_profile': recipe.qualityProfile,
        'roast_context': recipe.roastContext,
        'dose_g': recipe.doseG,
        'water_volume_ml': recipe.waterVolumeMl,
        'grind_size': recipe.grindSize,
        'temperature_c': recipe.temperatureC,
        'brewing_time_s': recipe.brewingTimeS,
        'steps': recipe.steps.isEmpty ? null : jsonEncode(_stepsToJson(recipe.steps)),
        'video_url': recipe.videoUrl,
        'notes': recipe.notes,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Future<void> deleteUserRecipe(String recipeId) async {
    final db = await _db;
    // Tombstone dulu — sama seperti deleteAnalysis (D-32). Tanpa ini resep
    // akan muncul lagi saat pull dari device lain.
    final rows = await db.query(
      'user_brew_recipes',
      columns: ['uuid'],
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      limit: 1,
    );
    final uuid = rows.isEmpty ? null : rows.first['uuid'] as String?;
    if (uuid != null) {
      await db.insert(
        'sync_deletes',
        {
          'uuid': uuid,
          'table_name': 'user_brew_recipes',
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await db.delete(
      'user_brew_recipes',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
    );
  }

  Future<List<BrewTool>> _getToolsForMethod(Database db, String methodId) async {
    final rows = await db.rawQuery('''
      SELECT t.tool_id, t.tool_name, t.category, t.image_asset, t.description,
             mt.is_required, mt.notes
      FROM brew_method_tools mt
      JOIN brew_tools t ON mt.tool_id = t.tool_id
      WHERE mt.method_id = ?
      ORDER BY mt.is_required DESC, t.tool_id ASC
    ''', [methodId]);

    return rows.map((r) => BrewTool.fromMap(r)).toList();
  }

  BrewMethod _parseMethod(Map<String, dynamic> row, List<BrewTool> tools) {
    return BrewMethod(
      methodId: row['method_id'] as String,
      methodName: row['method_name'] as String,
      methodType: row['method_type'] as String,
      subtitle: row['subtitle'] as String? ?? '',
      imageAsset: row['image_asset'] as String?,
      description: row['description'] as String? ?? '',
      tools: tools,
    );
  }

  BrewRecipe _parseRecipe(Map<String, dynamic> row) {
    return BrewRecipe(
      recipeId: row['recipe_id'] as String,
      name: row['name'] as String? ?? '',
      methodId: row['method_id'] as String,
      species: row['species'] as String,
      qualityProfile: row['quality_profile'] as String,
      roastContext: row['roast_context'] as String,
      doseG: (row['dose_g'] as num?)?.toDouble(),
      waterVolumeMl: row['water_volume_ml'] as int?,
      grindSize: row['grind_size'] as String?,
      temperatureC: row['temperature_c'] as int?,
      brewingTimeS: row['brewing_time_s'] as int?,
      source: row['source'] as String? ?? '',
      isDefault: (row['is_default'] as int? ?? 0) == 1,
      steps: _parseSteps(row['steps'] as String?),
      notes: row['notes'] as String?,
      videoUrl: row['video_url'] as String?,
    );
  }

  /// Parse baris `user_brew_recipes`. Tabel ini tidak punya kolom
  /// `source`/`is_default` → di-mapping tetap: `USER` / `false` (di luar
  /// lookup rekomendasi & reseed KB).
  BrewRecipe _parseUserRecipe(Map<String, dynamic> row) {
    return BrewRecipe(
      recipeId: row['recipe_id'] as String,
      name: row['name'] as String? ?? '',
      methodId: row['method_id'] as String?,
      methodName: row['method_name'] as String? ?? '',
      species: row['species'] as String,
      qualityProfile: row['quality_profile'] as String,
      roastContext: row['roast_context'] as String,
      doseG: (row['dose_g'] as num?)?.toDouble(),
      waterVolumeMl: row['water_volume_ml'] as int?,
      grindSize: row['grind_size'] as String?,
      temperatureC: row['temperature_c'] as int?,
      brewingTimeS: row['brewing_time_s'] as int?,
      source: 'USER',
      isDefault: false,
      steps: _parseSteps(row['steps'] as String?),
      notes: row['notes'] as String?,
      videoUrl: row['video_url'] as String?,
    );
  }

  /// Decode kolom JSON `steps` (shape sama untuk KB & resep user).
  List<BrewStep> _parseSteps(String? stepsRaw) {
    if (stepsRaw == null || stepsRaw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(stepsRaw) as List<dynamic>;
      return decoded.map((s) {
        final sMap = s as Map<String, dynamic>;
        return BrewStep(
          stepNo: sMap['stepNo'] as int? ?? 1,
          phase: sMap['phase'] == 'prep'
              ? BrewStepPhase.prep
              : BrewStepPhase.brew,
          title: sMap['title'] as String? ?? '',
          description: sMap['description'] as String? ?? '',
          targetTime: sMap['targetTime'] as String?,
          callout: sMap['callout'] as String?,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Encode langkah untuk kolom JSON `steps` (shape sama dengan KB).
  List<Map<String, Object?>> _stepsToJson(List<BrewStep> steps) =>
      steps
          .map((s) => <String, Object?>{
                'stepNo': s.stepNo,
                'phase': s.phase == BrewStepPhase.prep ? 'prep' : 'brew',
                'title': s.title,
                'description': s.description,
                if (s.targetTime != null && s.targetTime!.isNotEmpty)
                  'targetTime': s.targetTime,
                if (s.callout != null && s.callout!.isNotEmpty)
                  'callout': s.callout,
              })
          .toList();
}
