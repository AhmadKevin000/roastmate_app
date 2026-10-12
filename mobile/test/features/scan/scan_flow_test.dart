// Widget test: alur scan — simulasi delay analisis lalu membuka Detail Inspeksi.
//
// Pipeline ML belum ada; hasil memakai data mock dengan `batchName` ditimpa
// nama jenis biji yang diisi pada form setup.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pbl_sem5/features/scan/presentation/viewmodels/scan_setup_view_model.dart';
import 'package:pbl_sem5/features/scan/presentation/views/scan_view.dart';
import 'package:pbl_sem5/shared/models/analysis_result.dart';

Widget _app() => ProviderScope(
  overrides: [scanBatchNameProvider.overrideWith((ref) => 'Gayo Natural')],
  child: MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: '/scan',
      routes: <RouteBase>[
        GoRoute(
          path: '/scan',
          builder: (context, state) => const CameraScreen(),
        ),
        GoRoute(
          path: '/result/:analysisId',
          builder: (context, state) {
            final result = state.extra as InspectionResult?;
            return Scaffold(
              body: Center(
                child: Text('RESULT:${result?.batchName ?? 'null'}'),
              ),
            );
          },
        ),
      ],
    ),
  ),
);

void main() {
  testWidgets(
    'Shutter menampilkan loading lalu membuka hasil dengan nama biji',
    (tester) async {
      await tester.pumpWidget(_app());

      // Biarkan inisialisasi kamera (gagal di test) selesai.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('scan_shutter_button')));
      await tester.pump(); // mulai takePicture()
      await tester.pump(); // setState(_isAnalyzing = true)

      // Simulasi analisis tampil.
      expect(find.text('Menganalisis biji kopi…'), findsOneWidget);
      expect(find.textContaining('RESULT:'), findsNothing);

      // Setelah delay ~2 detik, hasil terbuka.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('RESULT:Gayo Natural'), findsOneWidget);

      // Layar kamera harus keluar dari stack (kamera dilepas) — bukan tetap
      // aktif di belakang halaman hasil.
      expect(find.byType(CameraScreen), findsNothing);
    },
  );
}
