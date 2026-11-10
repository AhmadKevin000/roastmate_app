import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pbl_sem5/core/database/schema.dart';
import 'package:pbl_sem5/features/brew/data/repositories/brewing_repository_impl.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: kSchemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          for (final stmt in kCreateTableStatements) {
            await db.execute(stmt);
          }
          for (final stmt in kCreateIndexStatements) {
            await db.execute(stmt);
          }
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('insert tools, methods, pivot and retrieve via BrewingRepository', () async {
    // 1. Insert Tools
    await db.insert('brew_tools', {
      'tool_id': 'T001',
      'tool_name': 'Dripper V60',
      'category': 'dripper',
      'image_asset': 'assets/images/tools/dripper_v60.png',
      'description': 'Dripper kerucut 60 derajat.',
    });
    await db.insert('brew_tools', {
      'tool_id': 'T002',
      'tool_name': 'Paper Filter V60',
      'category': 'filter',
      'image_asset': 'assets/images/tools/paper_filter.png',
      'description': 'Kertas filter.',
    });

    // 2. Insert Method
    await db.insert('brew_methods', {
      'method_id': 'M001',
      'method_name': 'V60 / Pour Over',
      'method_type': 'pour_over',
      'subtitle': 'Drip manual',
      'image_asset': 'assets/images/methods/v60.png',
      'description': 'Clean extraction',
    });

    // 3. Link Tools
    await db.insert('brew_method_tools', {
      'method_id': 'M001',
      'tool_id': 'T001',
      'is_required': 1,
      'notes': 'Ukuran 01',
    });
    await db.insert('brew_method_tools', {
      'method_id': 'M001',
      'tool_id': 'T002',
      'is_required': 1,
      'notes': null,
    });

    // 4. Insert Recipe
    await db.insert('brew_recipes', {
      'recipe_id': 'R001',
      'method_id': 'M001',
      'species': 'Arabica',
      'quality_profile': 'High',
      'roast_context': 'Light/Medium',
      'dose_g': 15.0,
      'water_volume_ml': 225,
      'grind_size': 'Medium-Fine',
      'temperature_c': 92,
      'brewing_time_s': 165,
      'source': 'BR001',
      'is_default': 1,
      'steps': jsonEncode([
        {'stepNo': 1, 'phase': 'prep', 'title': 'Siapkan Alat', 'description': 'Bilas filter'},
        {'stepNo': 1, 'phase': 'brew', 'title': 'Blooming', 'description': '45ml air'}
      ]),
      'notes': 'Nikmati selagi hangat',
    });

    // Repository test with in-memory db
    final repo = BrewingRepositoryImpl(database: db);
    final methods = await repo.getMethods();
    expect(methods.length, 1);
    expect(methods.first.methodName, 'V60 / Pour Over');
    expect(methods.first.imageAsset, 'assets/images/methods/v60.png');
    expect(methods.first.tools.length, 2);
    expect(methods.first.tools.first.toolName, 'Dripper V60');

    final recipes = await repo.getRecipesForMethod('M001');
    expect(recipes.length, 1);
    expect(recipes.first.species, 'Arabica');
    expect(recipes.first.doseG, 15.0);
    expect(recipes.first.waterVolumeMl, 225);
    expect(recipes.first.prepSteps.length, 1);
    expect(recipes.first.brewSteps.length, 1);

    final defaultRecipe = await repo.getDefaultRecipe('M001');
    expect(defaultRecipe, isNotNull);
    expect(defaultRecipe?.recipeId, 'R001');

    final allTools = await repo.getAllTools();
    expect(allTools.length, 2);
  });
}
