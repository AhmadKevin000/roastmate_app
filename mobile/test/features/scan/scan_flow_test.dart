// Widget test: alur scan — overlay analisis lalu membuka Detail Inspeksi.
//
// Di lingkungan widget: sumber template di-override (tanpa I/O asset) dan
// DB tidak tersedia (tanpa sqflite) — alur harus tetap membuka layar hasil
// dari data in-memory + snackbar (AC-04).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pbl_sem5/features/analysis/data/sources/analysis_template_source.dart';
import 'package:pbl_sem5/features/analysis/domain/entities/analysis_template.dart';
import 'package:pbl_sem5/features/scan/presentation/viewmodels/scan_setup_view_model.dart';
import 'package:pbl_sem5/features/scan/presentation/views/scan_view.dart';
import 'package:pbl_sem5/shared/enums/defect_class.dart';
import 'package:pbl_sem5/shared/models/analysis_result.dart';

const AnalysisTemplate _kTemplate = AnalysisTemplate(
  id: 'TPL-FIXED',
  species: 'Arabica',
  roast: 'Light',
  roastConfidence: 0.9,
  roastDistribution: {'Light': 0.8, 'Medium': 0.2},
  visibleBeans: 28,
  defectCounts: {
    DefectClass.normal: 26,
    DefectClass.quaker: 1,
    DefectClass.broken: 1,
  },
  shapeUniformity: 0.88,
  sizeUniformity: 0.84,
  roastUniformity: 0.81,
  summaryText: 'Ringkasan template test.',
);

/// Fake tanpa I/O asset (rootBundle tak dapat diandalkan di fake-async).
class _FakeTemplateSource extends AnalysisTemplateSource {
  @override
  Future<List<AnalysisTemplate>> loadAll() async => const [_kTemplate];
}

Widget _app() => ProviderScope(
  overrides: [
    scanBatchNameProvider.overrideWith((ref) => 'Gayo Natural'),
    analysisTemplateSourceProvider.overrideWithValue(_FakeTemplateSource()),
  ],
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
      await tester.pump(); // takePicture() → template → DB (gagal, di-catch)
      await tester.pump(); // setState(_isAnalyzing = true)

      // Simulasi analisis tampil.
      expect(find.text('Menganalisis biji kopi…'), findsOneWidget);
      expect(find.textContaining('RESULT:'), findsNothing);

      // Setelah delay ~2 detik, hasil terbuka.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('RESULT:Gayo Natural'), findsOneWidget);

      // DB gagal (tanpa sqflite di lingkungan widget) → snackbar (AC-04),
      // layar hasil tetap terbuka dari data in-memory.
      expect(find.text('Gagal menyimpan ke riwayat'), findsOneWidget);

      // Layar kamera harus keluar dari stack (kamera dilepas) — bukan tetap
      // aktif di belakang halaman hasil.
      expect(find.byType(CameraScreen), findsNothing);
    },
  );
}
