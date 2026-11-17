import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/features/home/domain/entities/home_summary.dart';
import 'package:pbl_sem5/shared/enums/indicative_grade.dart';
import 'package:pbl_sem5/shared/utils/date_formatter.dart';

HomeAnalysisSummary _item({
  int qualityScore = 82,
  String species = SpeciesLabels.arabica,
  DateTime? createdAt,
  String name = 'Batch A',
}) {
  return HomeAnalysisSummary(
    id: 1,
    name: name,
    createdAt: createdAt ?? DateTime(2026, 3, 12, 10, 24),
    species: species,
    visibleBeans: 24,
    qualityScore: qualityScore,
  );
}

void main() {
  group('HomeSummary', () {
    test('ringkasan kosong tidak punya analisis dan porsi 0', () {
      const summary = HomeSummary.empty();

      expect(summary.isEmpty, isTrue);
      expect(summary.totalAnalyses, 0);
      expect(summary.averageScore, 0);
      expect(summary.countOf(SpeciesLabels.arabica), 0);
      expect(summary.shareOf(SpeciesLabels.arabica), 0);
      expect(summary.recentAnalyses, isEmpty);
    });

    test('menghitung jumlah per species dan porsinya', () {
      const summary = HomeSummary(
        totalAnalyses: 4,
        averageScore: 80,
        speciesCounts: <String, int>{
          SpeciesLabels.arabica: 3,
          SpeciesLabels.mixed: 1,
        },
        recentAnalyses: <HomeAnalysisSummary>[],
      );

      expect(summary.countOf(SpeciesLabels.arabica), 3);
      expect(summary.shareOf(SpeciesLabels.arabica), 0.75);
      expect(summary.countOf(SpeciesLabels.mixed), 1);
      expect(summary.shareOf(SpeciesLabels.mixed), 0.25);
      // Species yang tidak muncul dihitung 0, bukan error.
      expect(summary.countOf(SpeciesLabels.robusta), 0);
    });

    test('grade rata-rata diturunkan dari skor, bukan disimpan', () {
      const high = HomeSummary(
        totalAnalyses: 2,
        averageScore: 86,
        speciesCounts: <String, int>{SpeciesLabels.arabica: 2},
        recentAnalyses: <HomeAnalysisSummary>[],
      );
      const low = HomeSummary(
        totalAnalyses: 2,
        averageScore: 35,
        speciesCounts: <String, int>{SpeciesLabels.robusta: 2},
        recentAnalyses: <HomeAnalysisSummary>[],
      );

      expect(high.averageGrade, IndicativeGrade.specialty);
      expect(low.averageGrade, IndicativeGrade.offGrade);
    });
  });

  group('HomeAnalysisSummary', () {
    test('grade per item mengikuti ambang PRD', () {
      expect(_item(qualityScore: 85).grade, IndicativeGrade.specialty);
      expect(_item(qualityScore: 84).grade, IndicativeGrade.premium);
      expect(_item(qualityScore: 60).grade, IndicativeGrade.standard);
      expect(_item(qualityScore: 40).grade, IndicativeGrade.belowStandard);
      expect(_item(qualityScore: 39).grade, IndicativeGrade.offGrade);
    });

    test('label tanggal ringkas berbahasa Indonesia', () {
      expect(
        _item(createdAt: DateTime(2026, 3, 12, 10, 24)).shortDateLabel,
        '12 Mar, 10:24',
      );
      expect(formatShortDateLabel(DateTime(2026, 8, 5, 9, 3)), '05 Agu, 09:03');
    });
  });

  group('gradeForScore', () {
    test('batas ambang tepat di nilai batas', () {
      expect(gradeForScore(100), IndicativeGrade.specialty);
      expect(gradeForScore(85), IndicativeGrade.specialty);
      expect(gradeForScore(84.9), IndicativeGrade.premium);
      expect(gradeForScore(75), IndicativeGrade.premium);
      expect(gradeForScore(74.9), IndicativeGrade.standard);
      expect(gradeForScore(60), IndicativeGrade.standard);
      expect(gradeForScore(59.9), IndicativeGrade.belowStandard);
      expect(gradeForScore(40), IndicativeGrade.belowStandard);
      expect(gradeForScore(39.9), IndicativeGrade.offGrade);
      expect(gradeForScore(0), IndicativeGrade.offGrade);
    });

    test('label grade untuk tampilan', () {
      expect(IndicativeGrade.premium.label, 'Premium');
      expect(IndicativeGrade.belowStandard.label, 'Below Standard');
      expect(IndicativeGrade.offGrade.label, 'Off Grade');
    });
  });
}
