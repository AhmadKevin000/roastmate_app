// Uji `AnalysisTemplateSource` — 12 template (4 species × 3 roast),
// konsistensi Σcounts, dan skor sesuai tabel final Plan 1.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/features/analysis/data/sources/analysis_template_source.dart';
import 'package:pbl_sem5/features/analysis/domain/quality_engine.dart';
import 'package:pbl_sem5/shared/enums/quality_profile.dart';

const Map<String, int> _expectedScores = {
  'TPL-AR-L': 95,
  'TPL-AR-M': 90,
  'TPL-AR-D': 73,
  'TPL-RO-L': 87,
  'TPL-RO-M': 71,
  'TPL-RO-D': 56,
  'TPL-LI-L': 89,
  'TPL-LI-M': 71,
  'TPL-LI-D': 57,
  'TPL-MX-L': 89,
  'TPL-MX-M': 74,
  'TPL-MX-D': 57,
};

const Set<String> _expectedMatrix = {
  'Arabica|Light',
  'Arabica|Medium',
  'Arabica|Dark',
  'Robusta|Light',
  'Robusta|Medium',
  'Robusta|Dark',
  'Liberika|Light',
  'Liberika|Medium',
  'Liberika|Dark',
  'Mixed|Light',
  'Mixed|Medium',
  'Mixed|Dark',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnalysisTemplateSource', () {
    test('memuat 12 template dengan matriks 4 species × 3 roast lengkap',
        () async {
      final templates = await AnalysisTemplateSource().loadAll();
      expect(templates, hasLength(12));

      final keys = {
        for (final t in templates) '${t.species}|${t.roast}',
      };
      expect(keys, _expectedMatrix);
    });

    test('Σcounts == visible_beans pada tiap template', () async {
      final templates = await AnalysisTemplateSource().loadAll();
      for (final t in templates) {
        final total = t.defectCounts.values.fold<int>(0, (s, v) => s + v);
        expect(total, t.visibleBeans, reason: 'total ${t.id}');
      }
    });

    test('skor tiap template sesuai tabel final Plan 1', () async {
      final templates = await AnalysisTemplateSource().loadAll();
      final byId = {for (final t in templates) t.id: t};

      for (final entry in _expectedScores.entries) {
        final t = byId[entry.key]!;
        final dr =
            QualityEngine.defectRate(t.defectCounts, t.visibleBeans);
        expect(QualityEngine.qualityScore(dr), entry.value, reason: entry.key);
      }
    });

    test('ketiga profil (High/Medium/Low) muncul minimal satu kali', () async {
      final templates = await AnalysisTemplateSource().loadAll();
      final profiles = {
        for (final t in templates)
          QualityEngine.profile(
            QualityEngine.qualityScore(
              QualityEngine.defectRate(t.defectCounts, t.visibleBeans),
            ),
          ),
      };
      expect(
        profiles,
        {QualityProfile.high, QualityProfile.medium, QualityProfile.low},
      );
    });

    test('pick deterministik dengan seeded RNG & memilih dari daftar', () async {
      final templates = await AnalysisTemplateSource().loadAll();
      final source = AnalysisTemplateSource();

      final first = source.pick(templates, Random(42));
      final second = source.pick(templates, Random(42));
      expect(first.id, second.id);
      expect(templates.map((t) => t.id), contains(first.id));
    });
  });
}
