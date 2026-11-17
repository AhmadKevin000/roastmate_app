// Uji helper builder rekomendasi (Plan 3 §2.3/§7): rasio dari dose/water,
// format waktu detik → mm:ss, title + subtitle, dan ringkasan deterministic
// (summaryText D-20). Semua pure — tanpa DB.

import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/features/result/domain/entities/analysis_detail.dart';
import 'package:pbl_sem5/shared/models/analysis_result.dart';
import 'package:pbl_sem5/shared/utils/brew_label_helpers.dart';

void main() {
  group('brewRatioLabel', () {
    test('15g / 240ml → 1:16', () {
      expect(brewRatioLabel(doseG: 15, waterVolumeMl: 240), '1:16');
    });

    test('rasio non-bulat → satu desimal', () {
      expect(brewRatioLabel(doseG: 10, waterVolumeMl: 155), '1:15.5');
    });

    test('nilai hilang/tak valid → —', () {
      expect(brewRatioLabel(doseG: null, waterVolumeMl: 240), '—');
      expect(brewRatioLabel(doseG: 15, waterVolumeMl: null), '—');
      expect(brewRatioLabel(doseG: 0, waterVolumeMl: 240), '—');
    });
  });

  group('formatBrewSeconds', () {
    test('detik → mm:ss', () {
      expect(formatBrewSeconds(170), '02:50');
      expect(formatBrewSeconds(0), '00:00');
      expect(formatBrewSeconds(240), '04:00');
      expect(formatBrewSeconds(3600), '60:00');
    });
  });

  group('toBrewRecommendation', () {
    test('baris join penuh → label lengkap, sub kosong', () {
      final rec = toBrewRecommendation(<String, Object?>{
        'primary_method_name': 'V60 / Pour Over',
        'primary_method_subtitle': 'Metode Drip Perkusi Manual',
        'reason': 'reason test',
        'dose_g': 15.0,
        'water_volume_ml': 240,
        'grind_size': 'Medium-Fine',
        'temperature_c': 93,
        'brewing_time_s': 170,
      });

      expect(rec.methodTitle, 'V60 / Pour Over — Metode Drip Perkusi Manual');
      expect(rec.reasonText, 'reason test');
      expect(rec.ratio, '1:16');
      expect(rec.ratioSub, '15g : 240ml air');
      expect(rec.tempC, '93°C');
      expect(rec.tempCSub, '');
      expect(rec.grind, 'Medium-Fine');
      expect(rec.grindSub, '');
      expect(rec.targetTime, '02:50');
      expect(rec.targetTimeSub, '');
    });

    test('subtitle kosong → title tanpa pemisah', () {
      final rec = toBrewRecommendation(<String, Object?>{
        'primary_method_name': 'Kopi Tubruk Tradisional',
        'primary_method_subtitle': '',
        'reason': '',
      });
      expect(rec.methodTitle, 'Kopi Tubruk Tradisional');
    });

    test('parameter resep null → label —', () {
      final rec = toBrewRecommendation(<String, Object?>{
        'primary_method_name': 'V60 / Pour Over',
        'reason': '',
      });

      expect(rec.ratio, '—');
      expect(rec.ratioSub, '—');
      expect(rec.tempC, '—');
      expect(rec.grind, '');
      expect(rec.targetTime, '—');
    });
  });

  group('toAlternativeMethod', () {
    test('metode alternatif null → null', () {
      expect(toAlternativeMethod(<String, Object?>{}), isNull);
    });

    test('baris alternatif → title + ringkasan rasio/waktu', () {
      final alt = toAlternativeMethod(<String, Object?>{
        'alt_method_name': 'French Press',
        'alt_method_subtitle': 'Ekstraksi Immersion Rendam Total',
        'a_dose': 18.0,
        'a_water': 252,
        'a_grind': 'Coarse',
        'a_temp': 94,
        'a_time': 240,
      });

      expect(alt, isNotNull);
      expect(alt!.title, 'French Press — Ekstraksi Immersion Rendam Total');
      expect(alt.ratio, '1:14');
      expect(alt.ratioSub, '18g : 252ml air');
      expect(alt.tempC, '94°C');
      expect(alt.grind, 'Coarse');
      expect(alt.targetTime, '04:00');
      expect(alt.description, 'Rasio 1:14 · 04:00');
    });
  });

  group('buildAnalysisSummary', () {
    InspectionResult fixture({
      int qualityScore = 86,
      Map<DefectClass, int> defectCounts = const {
        DefectClass.normal: 26,
        DefectClass.quaker: 1,
        DefectClass.broken: 1,
      },
      int visibleBeans = 28,
    }) {
      return InspectionResult(
        batchLabel: 'Batch #042',
        batchName: 'Mandheling Honey Anaerob',
        analyzedAgo: '-',
        qualityScore: qualityScore,
        visibleBeans: visibleBeans,
        defectCounts: defectCounts,
        species: 'Arabica',
        roast: 'Light',
        summaryText: '',
        alternatives: const [],
        detections: const [],
        modelVersion: '-',
      );
    }

    test('satu kalimat deterministic + klause defect dominan', () {
      expect(
        buildAnalysisSummary(fixture()),
        'Mandheling Honey Anaerob (Arabica, Light): 28 biji, '
        'defect rate 3.6%, skor 86/100 (High). Defect dominan: Quaker.',
      );
    });

    test('tanpa defect → tanpa klause dominan', () {
      expect(
        buildAnalysisSummary(
          fixture(
            qualityScore: 100,
            visibleBeans: 30,
            defectCounts: const {DefectClass.normal: 30},
          ),
        ),
        'Mandheling Honey Anaerob (Arabica, Light): 30 biji, '
        'defect rate 0.0%, skor 100/100 (High).',
      );
    });
  });
}
