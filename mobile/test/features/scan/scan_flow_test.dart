// Widget test: alur scan — overlay analisis lalu membuka Detail Inspeksi.
//
// Di lingkungan widget: kamera & pipeline ML di-override (tanpa I/O nyata) dan
// DB tidak tersedia (tanpa sqflite) — alur harus tetap membuka layar hasil
// dari data in-memory + snackbar (AC-04).

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pbl_sem5/features/scan/presentation/viewmodels/scan_setup_view_model.dart';
import 'package:pbl_sem5/features/scan/presentation/viewmodels/scan_view_model.dart';
import 'package:pbl_sem5/features/scan/presentation/views/scan_view.dart';
import 'package:pbl_sem5/inference/batch_aggregation.dart';
import 'package:pbl_sem5/inference/inference_pipeline.dart';
import 'package:pbl_sem5/shared/enums/defect_class.dart';
import 'package:pbl_sem5/shared/models/analysis_result.dart';

const BatchSummary _kSummary = BatchSummary(
  visibleBeans: 28,
  species: 'Arabica',
  speciesConfidence: 0.93,
  roast: 'Light',
  roastConfidence: 0.9,
  roastDistribution: {'Light': 0.8, 'Medium': 0.2},
  defectCounts: {
    DefectClass.normal: 26,
    DefectClass.quaker: 1,
    DefectClass.broken: 1,
  },
  defectRate: 0.035,
  shapeUniformity: 0.88,
  sizeUniformity: 0.84,
  roastUniformity: 0.9,
  detections: <BeanDetection>[],
);

/// Kamera palsu: selalu mengembalikan satu file tanpa menyentuh plugin.
class _FakeCameraViewModel extends CameraViewModel {
  _FakeCameraViewModel(this.file);

  final XFile file;

  @override
  Future<void> initCamera() async {}

  @override
  Future<XFile?> takePicture() async => file;

  @override
  Future<void> stopPreview() async {}
}

/// Pipeline palsu tanpa model TFLite.
class _FakePipeline implements InferencePipeline {
  const _FakePipeline();

  @override
  Future<BatchSummary> analyze(String imagePath) async => _kSummary;
}

/// Pipeline yang meniru foto tanpa biji terdeteksi.
class _EmptyPipeline implements InferencePipeline {
  const _EmptyPipeline();

  @override
  Future<BatchSummary> analyze(String imagePath) async =>
      throw const NoBeansDetectedException();
}

Widget _app({InferencePipeline pipeline = const _FakePipeline()}) =>
    ProviderScope(
      overrides: [
        scanBatchNameProvider.overrideWith((ref) => 'Gayo Natural'),
        cameraViewModelProvider.overrideWith(
          (ref) => _FakeCameraViewModel(XFile('/tmp/fake_batch.jpg')),
        ),
        inferencePipelineProvider.overrideWithValue(pipeline),
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
      await tester.pump(); // takePicture() → inference → DB (gagal, di-catch)
      await tester.pump(); // setState(_isAnalyzing = true)

      // Simulasi analisis tampil.
      expect(find.text('Menganalisis biji kopi…'), findsOneWidget);
      expect(find.textContaining('RESULT:'), findsNothing);

      // Setelah delay minimal overlay, hasil terbuka.
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

  testWidgets('Tidak ada biji terdeteksi → pesan error, tidak membuka hasil', (
    tester,
  ) async {
    await tester.pumpWidget(_app(pipeline: const _EmptyPipeline()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('scan_shutter_button')));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Tidak ada biji kopi'), findsOneWidget);
    expect(find.textContaining('RESULT:'), findsNothing);
    expect(find.byType(CameraScreen), findsOneWidget);
  });
}
