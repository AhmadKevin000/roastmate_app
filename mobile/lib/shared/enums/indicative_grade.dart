/// Grade indikatif untuk tampilan, diturunkan dari quality profile.
///
/// Pemetaan: `docs/DECISIONS.md` D-02.
library;

enum IndicativeGrade { specialty, premium, standard, belowStandard, offGrade }

/// Label tampilan grade (mis. `Specialty`, `Below Standard`).
extension IndicativeGradeLabel on IndicativeGrade {
  String get label {
    switch (this) {
      case IndicativeGrade.specialty:
        return 'Specialty';
      case IndicativeGrade.premium:
        return 'Premium';
      case IndicativeGrade.standard:
        return 'Standard';
      case IndicativeGrade.belowStandard:
        return 'Below Standard';
      case IndicativeGrade.offGrade:
        return 'Off Grade';
    }
  }
}

/// Pemetaan skor 0–100 ke grade indikatif.
///
/// Ambang mengikuti `docs/PRD.md` bagian 8 dan `docs/DECISIONS.md` D-02;
/// nilainya parameter sistem, bukan hasil model.
IndicativeGrade gradeForScore(num score) {
  if (score >= 85) return IndicativeGrade.specialty;
  if (score >= 75) return IndicativeGrade.premium;
  if (score >= 60) return IndicativeGrade.standard;
  if (score >= 40) return IndicativeGrade.belowStandard;
  return IndicativeGrade.offGrade;
}
