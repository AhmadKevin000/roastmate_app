// Test CRUD resep user (`user_brew_recipes`) — SQLite in-memory via ffi.
//
// Ekspektasi mengikuti `docs/DATABASE_SCHEMA.md` §9.5 dan Plan 4 §2:
// id `U<epoch-micros>`, mapping `source='USER'`/`isDefault=false`/`steps=[]`,
// urutan `created_at DESC`, FK ke `brew_methods`.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pbl_sem5/core/database/schema.dart';
import 'package:pbl_sem5/features/brew/data/repositories/brewing_repository_impl.dart';
import 'package:pbl_sem5/features/brew/domain/entities/brew_recipe.dart';

/// Database in-memory skema terkini + satu metode KB agar FK `method_id`
/// bisa lolos.
Future<Database> openRecipeDatabase() async {
  return databaseFactoryFfi.openDatabase(
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
        await db.insert('brew_methods', {
          'method_id': 'M001',
          'method_name': 'V60 / Pour Over',
          'method_type': 'pour_over',
        });
      },
    ),
  );
}

BrewRecipe fixtureRecipe({String name = 'Resep Uji'}) => BrewRecipe(
      recipeId: '',
      name: name,
      methodId: 'M001',
      species: 'Arabica',
      qualityProfile: 'High',
      roastContext: 'Light',
      doseG: 15,
      waterVolumeMl: 240,
      grindSize: 'Medium-Fine',
      temperatureC: 93,
      brewingTimeS: 170,
      notes: 'Catatan uji',
      source: 'USER',
    );

void main() {
  sqfliteFfiInit();

  late Database db;
  late BrewingRepositoryImpl repo;

  setUp(() async {
    db = await openRecipeDatabase();
    repo = BrewingRepositoryImpl(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('insert → getUserRecipes memuat resep (roundtrip, source USER)',
      () async {
    await repo.insertUserRecipe(fixtureRecipe());

    final recipes = await repo.getUserRecipes();
    expect(recipes, hasLength(1));
    final r = recipes.single;
    expect(r.recipeId, startsWith('U'));
    expect(r.name, 'Resep Uji');
    expect(r.methodId, 'M001');
    expect(r.species, 'Arabica');
    expect(r.qualityProfile, 'High');
    expect(r.roastContext, 'Light');
    expect(r.doseG, 15);
    expect(r.waterVolumeMl, 240);
    expect(r.grindSize, 'Medium-Fine');
    expect(r.temperatureC, 93);
    expect(r.brewingTimeS, 170);
    expect(r.notes, 'Catatan uji');
    expect(r.source, 'USER');
    expect(r.isDefault, isFalse, reason: 'resep user bukan default KB');
    expect(r.steps, isEmpty, reason: 'v1 tanpa langkah seduh');
  });

  test('dua insert → urutan created_at DESC (terbaru dulu)', () async {
    await repo.insertUserRecipe(fixtureRecipe(name: 'Resep A'));
    // Jeda agar timestamp ISO (presisi ms) pasti berbeda.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.insertUserRecipe(fixtureRecipe(name: 'Resep B'));

    final names = (await repo.getUserRecipes()).map((r) => r.name).toList();
    expect(names, ['Resep B', 'Resep A']);
  });

  test('delete → resep hilang', () async {
    await repo.insertUserRecipe(fixtureRecipe());
    final id = (await repo.getUserRecipes()).single.recipeId;

    await repo.deleteUserRecipe(id);

    expect(await repo.getUserRecipes(), isEmpty);
  });

  test('delete id tak dikenal → no-op tanpa error', () async {
    await repo.insertUserRecipe(fixtureRecipe());

    await repo.deleteUserRecipe('U_TIDAK_ADA');

    expect(await repo.getUserRecipes(), hasLength(1));
  });

  test('insert method_id tidak ada di KB → throw (FK)', () async {
    await expectLater(
      repo.insertUserRecipe(BrewRecipe(
        recipeId: '',
        name: 'Resep FK',
        methodId: 'M999',
        species: 'Arabica',
        qualityProfile: 'High',
        roastContext: 'Light',
        source: 'USER',
      )),
      throwsA(isA<Exception>()),
    );
    expect(await repo.getUserRecipes(), isEmpty);
  });
}
