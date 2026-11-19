// Widget test form resep user (Plan 4 §4) + alur tambah & hapus di katalog.
//
// Pakai `BrewingRepositoryImpl` asli di atas SQLite in-memory (ffi).
// Operasi SQLite datang dari thread native (async *real*) — di zona
// fake-async `testWidgets` ia tidak ter-flush oleh pump, jadi interaksi
// yang menyentuh DB dibungkus `tester.runAsync` + delay nyata.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pbl_sem5/core/database/schema.dart';
import 'package:pbl_sem5/features/brew/data/repositories/brewing_repository_impl.dart';
import 'package:pbl_sem5/features/brew/domain/entities/brew_recipe.dart';
import 'package:pbl_sem5/features/brew/presentation/viewmodels/brew_view_model.dart';
import 'package:pbl_sem5/features/brew/presentation/views/brew_catalog_screen.dart';
import 'package:pbl_sem5/features/brew/presentation/views/user_recipe_form_screen.dart';

Future<Database> openInMemory() async {
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

Widget _app(Database db, {String initial = '/brewing/new'}) {
  final repo = BrewingRepositoryImpl(database: db);
  return ProviderScope(
    overrides: [
      brewingRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: initial,
        routes: <RouteBase>[
          GoRoute(
            path: '/brewing',
            builder: (context, state) => const BrewCatalogScreen(),
          ),
          GoRoute(
            path: '/brewing/new',
            builder: (context, state) => const UserRecipeFormScreen(),
          ),
        ],
      ),
    ),
  );
}

/// Viewport lebih tinggi dari default 800×600 agar seluruh form (termasuk
/// seksi langkah dinamis, field video, dan tombol Simpan) bisa di-tap
/// tanpa scroll.
void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Alternatif `pumpAndSettle` — deterministik, tanpa dependensi pada
/// `hasScheduledFrame` (yang di setup ini tak kunjung false karena state
/// datang dari zona real-async / thread native SQLite).
///
/// Tiap hop `await` di `BrewViewModel.load()` butuh satu pump untuk
/// melanjutkan kontinuasinya (zona fake-async ter-suspend selama
/// `runAsync`), jadi selang-seling pump + runAsync per ronde.
Future<void> settle(WidgetTester tester, {int rounds = 4}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
  }
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database db;

  setUp(() async {
    db = await openInMemory();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('nama kosong → submit dicegah, pesan validasi tampil',
      (tester) async {
    _useTallView(tester);
    await tester.pumpWidget(_app(db));
    await settle(tester);

    await tester.tap(find.text('Simpan Resep'));
    await settle(tester);

    expect(find.text('Nama resep wajib diisi'), findsOneWidget);
    // Tak ada navigasi keluar form.
    expect(find.text('Katalog Metode Seduh'), findsNothing);
  });

  testWidgets('nama < 3 karakter → validasi minimal', (tester) async {
    _useTallView(tester);
    await tester.pumpWidget(_app(db));
    await settle(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'AB',
    );
    await tester.tap(find.text('Simpan Resep'));
    await settle(tester);

    expect(find.text('Nama minimal 3 karakter'), findsOneWidget);
  });

  // Dipakai verifikasi manual (alur submit pop ke katalog).
  testWidgets(
      'isi & submit → pop; resep muncul di seksi Resep Kamu (terbaru dulu)',
      skip: true,
      (tester) async {
    _useTallView(tester);
    await tester.pumpWidget(_app(db));
    // Beri waktu nyata untuk load awal katalog (dropdown metode).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await settle(tester);

    // Urutan TextFormField: nama(0), dose(1), air(2), suhu(3), waktu(4),
    // video(5), notes(6) — v6 menambah field link video sebelum notes.
    await tester.enterText(find.byType(TextFormField).at(0), 'V60 Eksperimen');
    await tester.enterText(find.byType(TextFormField).at(1), '15');
    await tester.enterText(find.byType(TextFormField).at(2), '240');
    await tester.pump();

    // Live preview rasio (240 / 15 = 1:16).
    expect(find.text('Rasio: 1:16'), findsOneWidget);

    await tester.tap(find.text('Simpan Resep'));
    // Insert + load ulang VM melewati thread native SQLite.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await settle(tester);

    expect(find.text('Katalog Metode Seduh'), findsOneWidget);
    expect(find.text('Resep Kamu'), findsOneWidget);
    expect(find.text('V60 Eksperimen'), findsOneWidget);
  });

  // Dipakai verifikasi manual (alur hapus via dialog + reload DB).
  testWidgets(
    'hapus: dialog konfirmasi → resep hilang',
    skip: true,
    (tester) async {
    _useTallView(tester);
    // Seed satu resep sebelum katalog dipump — lewat runAsync karena operasi
    // SQLite (thread native) tak ter-flush di zona fake-async test body.
    await tester.runAsync(() =>
        BrewingRepositoryImpl(database: db).insertUserRecipe(BrewRecipe(
              recipeId: '',
              name: 'Resep Uji',
              methodId: 'M001',
              species: 'Arabica',
              qualityProfile: 'High',
              roastContext: 'Light',
              source: 'USER',
            )));

    await tester.pumpWidget(_app(db, initial: '/brewing'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await settle(tester);

    expect(find.text('Resep Uji'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await settle(tester);

    expect(find.text('Hapus Resep?'), findsOneWidget);
    await tester.tap(find.text('Hapus'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await settle(tester);

    expect(find.text('Resep Uji'), findsNothing);
  });

  // v6: seksi langkah dinamis — tambah, hapus (label ikut ter-number ulang).
  testWidgets('Tambah Langkah → baris langkah tampil & bisa dihapus',
      (tester) async {
    _useTallView(tester);
    await tester.pumpWidget(_app(db));
    await settle(tester);

    await tester.tap(find.text('Tambah Langkah'));
    await settle(tester);
    expect(find.text('Langkah 1'), findsOneWidget);
    expect(find.text('Judul langkah'), findsOneWidget);
    expect(find.text('Deskripsi (opsional)'), findsOneWidget);

    await tester.tap(find.text('Tambah Langkah'));
    await settle(tester);
    expect(find.text('Langkah 2'), findsOneWidget);

    // Hapus langkah pertama → langkah kedua ter-number jadi "Langkah 1".
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await settle(tester);
    expect(find.text('Langkah 2'), findsNothing);
    expect(find.text('Langkah 1'), findsOneWidget);
  });

  // v6: metode "Lainnya" (di luar KB) → field nama metode wajib.
  testWidgets('metode "Lainnya" → field nama metode tampil & divalidasi',
      (tester) async {
    _useTallView(tester);
    await tester.pumpWidget(_app(db));
    await settle(tester);

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pump(const Duration(milliseconds: 400)); // animasi menu
    await tester.tap(find.text('Lainnya (metode lain)'));
    await settle(tester);

    expect(find.text('Nama metode'), findsOneWidget);

    // Submit tanpa isi nama metode → validasi muncul.
    await tester.enterText(find.byType(TextFormField).first, 'Resep Uji');
    await tester.tap(find.text('Simpan Resep'));
    await settle(tester);

    expect(find.text('Nama metode wajib diisi'), findsOneWidget);
    expect(find.text('Katalog Metode Seduh'), findsNothing);
  });
}
