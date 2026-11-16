/// Kelas defect kanonik (4 kelas final hasil training ML_PBL).
///
/// Enum yang disimpan/ditampilkan memakai Title Case
/// (`docs/DATABASE_SCHEMA.md` §11); label Dart memakai camelCase.
library;

enum DefectClass { normal, quaker, broken, severe }

/// Petakan nama kanonik (Title Case, `DATABASE_SCHEMA.md` §7/§11) ke enum.
///
/// Return `null` bila nama bukan kelas defect yang dikenal.
DefectClass? defectClassFromName(String name) {
  switch (name) {
    case 'Normal':
      return DefectClass.normal;
    case 'Quaker':
      return DefectClass.quaker;
    case 'Broken':
      return DefectClass.broken;
    case 'Severe':
      return DefectClass.severe;
    default:
      return null;
  }
}

