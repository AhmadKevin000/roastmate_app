import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

/// Mengisi knowledge base (`brew_methods`, `brew_recipes`) dari seed JSON.
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

    final raw = await rootBundle.loadString(kKnowledgeSeedAsset);
    final Map<String, dynamic> data =
        jsonDecode(raw) as Map<String, dynamic>;

    final methods = (data['methods'] as List<dynamic>? ?? <dynamic>[]);
    final recipes = (data['recipes'] as List<dynamic>? ?? <dynamic>[]);

    await _db.transaction((txn) async {
      for (final m in methods) {
        await txn.insert('brew_methods', _methodRow(m as Map<String, dynamic>));
      }
      for (final r in recipes) {
        await txn.insert('brew_recipes', _recipeRow(r as Map<String, dynamic>));
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

  Map<String, Object?> _methodRow(Map<String, dynamic> m) => <String, Object?>{
        'method_id': m['method_id'],
        'method_name': m['method_name'],
        'method_type': m['method_type'],
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
