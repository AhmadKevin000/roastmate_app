// Uji penilaian pribadi v8 (D-31): nilai awal dari DB tampil di kartu, dan
// penulisan bintang + catatan meng-update `analyses.personal_rating` /
// `personal_rating_note` lewat ViewModel.
//
// Penulisan DB diuji sebagai unit test (bukan `testWidgets`) karena fake async
// di widget test membuat `await db.update` tidak pernah selesai.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pbl_sem5/core/database/schema.dart';
import 'package:pbl_sem5/features/analysis/data/sources/analysis_repository.dart';
import 'package:pbl_sem5/features/result/presentation/viewmodels/personal_rating_view_model.dart';
import 'package:pbl_sem5/features/result/presentation/widgets/personal_rating_card.dart';

Future<Database> _openDb() => databaseFactoryFfi.openDatabase(
  inMemoryDatabasePath,
  options: OpenDatabaseOptions(
    version: kSchemaVersion,
    onCreate: (db, version) async {
      for (final stmt in kCreateTableStatements) {
        await db.execute(stmt);
      }
    },
  ),
);

Future<int> _insertAnalysis(Database db) => db.insert('analyses', {
  'created_at': '2026-01-01T00:00:00Z',
  'batch_label': 'Batch #042',
  'batch_name': 'Mandheling Honey Anaerob',
  'species': 'Arabica',
  'roast': 'Light',
  'visible_beans': 20,
  'quality_score': 86,
  'quality_profile': 'High',
});

Widget _host(Database db, {required int analysisId, int? initialStars, String? initialNote}) {
  return ProviderScope(
    overrides: [
      personalRatingProvider.overrideWith(
        (ref) => PersonalRatingViewModel(
          repositoryOpener: () async => AnalysisRepository(db),
        ),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PersonalRatingCard(
            ratingKey: 'Batch #042',
            analysisId: analysisId,
            initialStars: initialStars,
            initialNote: initialNote,
          ),
        ),
      ),
    ),
  );
}

void main() {
  sqfliteFfiInit();

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late int analysisId;

  setUp(() async {
    db = await _openDb();
    analysisId = await _insertAnalysis(db);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('nilai awal dari DB tampil dan catatan terisi', (tester) async {
    await tester.pumpWidget(
      _host(db, analysisId: analysisId, initialStars: 3, initialNote: 'manis'),
    );
    await tester.pumpAndSettle();

    expect(find.text('3/5'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.text('manis'), findsOneWidget);
  });

  // Penulisan DB diuji di level ViewModel, bukan widget: `testWidgets`
  // memakai fake async sehingga `await db.update` tidak pernah selesai
  // (test menggantung sampai timeout 10 menit).
  test('persist menulis bintang + catatan ke kolom analyses', () async {
    final vm = PersonalRatingViewModel(
      repositoryOpener: () async => AnalysisRepository(db),
    );
    vm.setStars('Batch #042', 5);
    vm.setNote('Batch #042', '  body tebal  ');

    expect(await vm.persist('Batch #042', analysisId), isTrue);

    final row = (await db.query(
      'analyses',
      where: 'id = ?',
      whereArgs: [analysisId],
    )).single;
    expect(row['personal_rating'], 5);
    expect(row['personal_rating_note'], 'body tebal');
  });

  test('persist tanpa bintang → false dan DB tidak berubah', () async {
    final vm = PersonalRatingViewModel(
      repositoryOpener: () async => AnalysisRepository(db),
    );

    expect(await vm.persist('Batch #042', analysisId), isFalse);

    final row = (await db.query(
      'analyses',
      where: 'id = ?',
      whereArgs: [analysisId],
    )).single;
    expect(row['personal_rating'], isNull);
  });

  test('kegagalan buka DB dikembalikan sebagai false, bukan exception', () async {
    final vm = PersonalRatingViewModel(
      repositoryOpener: () async => throw StateError('db tidak tersedia'),
    );
    vm.setStars('Batch #042', 3);

    expect(await vm.persist('Batch #042', analysisId), isFalse);
  });
}
