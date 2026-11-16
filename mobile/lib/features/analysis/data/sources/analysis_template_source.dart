import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/analysis_template.dart';

/// Path asset template analisis (pubspec sudah bundle `assets/knowledge/`).
const String kAnalysisTemplateAsset =
    'assets/knowledge/analysis_templates.json';

/// Species kanonik yang boleh muncul di template (D-13).
const Set<String> kKnownSpecies = {'Arabica', 'Robusta', 'Liberika', 'Mixed'};

/// Roast yang boleh muncul di template — `Green` dikecualikan (AC-04:
/// biji mentah tidak menerima parameter seduh).
const Set<String> kKnownRoast = {'Light', 'Medium', 'Dark'};

/// Sumber data template analisis — pengganti sementara hasil pipeline ML.
///
/// Load asset sekali, validasi fail-fast, lalu [pick] memilih satu template
/// acak seragam per sesi analisis.
class AnalysisTemplateSource {
  const AnalysisTemplateSource();

  /// Muat seluruh template.
  ///
  /// Lempar [StateError] bila asset rusak/inkonsisten (species/roast tak
  /// dikenal, Σcounts ≠ visible_beans, kombinasi duplikat).
  Future<List<AnalysisTemplate>> loadAll() async {
    final raw = await rootBundle.loadString(kAnalysisTemplateAsset);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final templates = (data['templates'] as List<dynamic>)
        .map((t) => AnalysisTemplate.fromMap(t as Map<String, dynamic>))
        .toList();

    final seen = <String>{};
    for (final t in templates) {
      if (!kKnownSpecies.contains(t.species)) {
        throw StateError('Template ${t.id}: species tidak dikenal "${t.species}"');
      }
      if (!kKnownRoast.contains(t.roast)) {
        throw StateError('Template ${t.id}: roast tidak dikenal "${t.roast}"');
      }
      final total = t.defectCounts.values.fold<int>(0, (s, v) => s + v);
      if (total != t.visibleBeans) {
        throw StateError(
          'Template ${t.id}: Σcounts ($total) != visible_beans (${t.visibleBeans})',
        );
      }
      if (!seen.add('${t.species}|${t.roast}')) {
        throw StateError('Template ${t.id}: kombinasi species|roast duplikat');
      }
    }
    return templates;
  }

  /// Pilih satu template acak seragam dari [all] dengan [rng].
  AnalysisTemplate pick(List<AnalysisTemplate> all, Random rng) =>
      all[rng.nextInt(all.length)];
}

/// Instance sumber template analisis untuk injeksi dependensi alur scan
/// (bisa di-override di widget test agar tanpa I/O asset).
final analysisTemplateSourceProvider = Provider<AnalysisTemplateSource>(
  (ref) => const AnalysisTemplateSource(),
);
