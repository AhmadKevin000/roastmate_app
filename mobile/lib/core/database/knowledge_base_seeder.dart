import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

/// Mengisi knowledge base (`brew_methods`, `brew_tools`, `brew_recipes`) dari seed JSON.
///
/// Alur: `JSON → SQLite`. Seeding hanya dijalankan bila tabel KB masih kosong,
/// sehingga aman dipanggil berkali-kali (idempoten).
class KnowledgeBaseSeeder {
  const KnowledgeBaseSeeder(this._db);

  final Database _db;

  Future<void> seedIfEmpty() async {
    final count = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COUNT(*) FROM brew_methods'),
    );
    if ((count ?? 0) > 0) return;
    await _seed();
  }

  /// Menghapus dan mengisi ulang data knowledge base (misal saat schema upgrade).
  Future<void> reseed() async {
    await _db.transaction((txn) async {
      await txn.delete('brew_method_tools');
      await txn.delete('brew_recipes');
      await txn.delete('brew_methods');
      await txn.delete('brew_tools');
    });
    await _seed();
  }

  Future<void> _seed() async {

    final raw = await rootBundle.loadString(kKnowledgeSeedAsset);
    final Map<String, dynamic> data =
        jsonDecode(raw) as Map<String, dynamic>;

    final tools = (data['tools'] as List<dynamic>? ?? <dynamic>[]);
    final methods = (data['methods'] as List<dynamic>? ?? <dynamic>[]);
    final recipes = (data['recipes'] as List<dynamic>? ?? <dynamic>[]);

    await _db.transaction((txn) async {
      // 1. Insert Tools
      for (final t in tools) {
        await txn.insert(
          'brew_tools',
          _toolRow(t as Map<String, dynamic>),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 2. Insert Methods & MethodTools relation
      for (final m in methods) {
        final mMap = m as Map<String, dynamic>;
        await txn.insert(
          'brew_methods',
          _methodRow(mMap),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        final methodTools = mMap['tools'] as List<dynamic>? ?? <dynamic>[];
        for (final mt in methodTools) {
          final mtMap = mt as Map<String, dynamic>;
          await txn.insert(
            'brew_method_tools',
            <String, Object?>{
              'method_id': mMap['method_id'],
              'tool_id': mtMap['tool_id'],
              'is_required': mtMap['is_required'] ?? 1,
              'notes': mtMap['notes'],
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // 3. Insert Recipes
      for (final r in recipes) {
        await txn.insert(
          'brew_recipes',
          _recipeRow(r as Map<String, dynamic>),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    final kbVersion = data['kb_version'] as String?;
    if (kbVersion != null) {
      await _db.insert(
        'meta',
        <String, Object?>{'key': kMetaKbVersion, 'value': kbVersion},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Map<String, Object?> _toolRow(Map<String, dynamic> t) => <String, Object?>{
        'tool_id': t['tool_id'],
        'tool_name': t['tool_name'],
        'category': t['category'],
        'image_asset': t['image_asset'],
        'description': t['description'],
      };

  Map<String, Object?> _methodRow(Map<String, dynamic> m) => <String, Object?>{
        'method_id': m['method_id'],
        'method_name': m['method_name'],
        'method_type': m['method_type'],
        'subtitle': m['subtitle'],
        'image_asset': m['image_asset'],
        'description': m['description'],
      };

  Map<String, Object?> _recipeRow(Map<String, dynamic> r) => <String, Object?>{
        'recipe_id': r['recipe_id'],
        'method_id': r['method_id'],
        'species': r['species'],
        'quality_profile': r['quality_profile'],
        'roast_context': r['roast_context'],
        'dose_g': r['dose_g'],
        'water_volume_ml': r['water_volume_ml'],
        'grind_size': r['grind_size'],
        'temperature_c': r['temperature_c'],
        'brewing_time_s': r['brewing_time_s'],
        'source': r['source'],
        'is_default': r['is_default'],
        'steps': r['steps'] == null ? null : jsonEncode(r['steps']),
        'notes': r['notes'],
      };
}

