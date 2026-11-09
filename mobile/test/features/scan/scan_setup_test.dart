// Widget test: form nama jenis biji sebelum scan.
//
// Fokus: validasi wajib isi, lalu nama tersimpan di provider dan navigasi
// menuju kamera.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pbl_sem5/features/scan/presentation/viewmodels/scan_setup_view_model.dart';
import 'package:pbl_sem5/features/scan/presentation/views/scan_setup_view.dart';

Widget _app() => ProviderScope(
  child: MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: '/scan/setup',
      routes: <RouteBase>[
        GoRoute(
          path: '/scan/setup',
          builder: (context, state) => const ScanSetupView(),
        ),
        GoRoute(
          path: '/scan',
          builder: (context, state) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) => Center(
                child: Text('CAMERA:${ref.watch(scanBatchNameProvider)}'),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);

void main() {
  testWidgets('Nama wajib diisi sebelum lanjut ke kamera', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lanjut ke Kamera'));
    await tester.pumpAndSettle();

    expect(find.text('Nama jenis biji wajib diisi'), findsOneWidget);
    expect(find.textContaining('CAMERA:'), findsNothing);
  });

  testWidgets('Spasi saja tetap dianggap kosong', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Lanjut ke Kamera'));
    await tester.pumpAndSettle();

    expect(find.text('Nama jenis biji wajib diisi'), findsOneWidget);
  });

  testWidgets('Nama tersimpan dan membuka kamera', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Gayo Natural');
    await tester.tap(find.text('Lanjut ke Kamera'));
    await tester.pumpAndSettle();

    expect(find.text('CAMERA:Gayo Natural'), findsOneWidget);
  });
}
