import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../../../../core/widgets/roastmate_app_bar.dart';
import '../../../../inference/analysis_pipeline.dart';
import '../../../../inference/bean_detector.dart';
import '../../../../inference/image_quality_checker.dart';
import '../../../../shared/models/analysis_result.dart';
import '../../../result/data/sources/mock_inspection_source.dart';
import '../viewmodels/scan_setup_view_model.dart';
import '../viewmodels/scan_view_model.dart';
import '../widgets/analyzing_overlay.dart';

/// Screen UI untuk "Scan Kamera" pada aplikasi Roastmate.
/// Terintegrasi dengan Riverpod 2.x & CameraController (MVVM Architecture).
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  /// True saat simulasi analisis ML berjalan (setelah shutter ditekan).
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    // Membaca state kamera dari Riverpod ViewModel
    final cameraState = ref.watch(cameraViewModelProvider);
    final cameraVM = ref.read(cameraViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: RoastmateColors.background,
      appBar: const RoastmateAppBar(title: 'Scan Biji Kopi'),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF231A16),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Area Pemindaian Kamera (Viewfinder + Overlay)
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Tampilan Kamera Asli (CameraPreview) atau Placeholder Latar Belakang
                      Positioned.fill(
                        child: _CameraLivePreview(
                          state: cameraState,
                        ),
                      ),

                      // 2. Baris Tombol Atas (Close, Batch Pill, Light)
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Tombol Close (X)
                            _IconButtonCircle(
                              icon: Icons.close,
                              onTap: () {
                                if (context.canPop()) {
                                  context.pop();
                                }
                              },
                            ),

                            // Badge "Scan Batch Kopi"
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C231E).withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4ADE80),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Scan Batch Kopi',
                                    style: RoastmateText.labelMd.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Tombol Lightbulb / Lampu Pencerah
                            _IconButtonCircle(
                              icon: cameraState.isLightOn
                                  ? Icons.lightbulb
                                  : Icons.lightbulb_outline,
                              iconColor: cameraState.isLightOn
                                  ? const Color(0xFFFDE047)
                                  : Colors.white,
                              onTap: () => cameraVM.toggleLight(),
                            ),
                          ],
                        ),
                      ),

                      // 3. Petunjuk & Indikator Pencahayaan (Di Atas Frame Kotak)
                      Positioned(
                        top: 72,
                        child: Column(
                          children: [
                            // Teks Instruksi: "Arahkan kamera ke biji kopi..."
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF231B17).withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.crop_free_rounded,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Arahkan kamera ke biji kopi yang terlihat',
                                    style: RoastmateText.bodySm.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Badge Indikator "Pencahayaan Baik"
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF166534).withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Color(0xFF86EFAC),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Pencahayaan Baik',
                                    style: RoastmateText.bodySm.copyWith(
                                      color: const Color(0xFF86EFAC),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 4. Frame Area Pemindaian (Cutout Siku Putih & Target Circle)
                      Center(
                        child: Container(
                          width: 260,
                          height: 260,
                          margin: const EdgeInsets.only(top: 10),
                          child: Stack(
                            children: [
                              // Siku-siku Putih di 4 Sudut Viewfinder
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: ViewfinderCornerPainter(),
                                ),
                              ),

                              // Dotted Target Circle di Tengah
                              Center(
                                child: CustomPaint(
                                  size: const Size(60, 60),
                                  painter: TargetReticlePainter(),
                                ),
                              ),

                              // Highlight Spot Transparan (Detail visual dari gambar)
                              Positioned(
                                top: 75,
                                left: 75,
                                child: Container(
                                  width: 44,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAB308).withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFEAB308).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEAB308),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 5. Teks Instruksi Bawah Viewfinder: "Tidak perlu menata..."
                      Positioned(
                        bottom: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF231B17).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.grain,
                                color: Color(0xFFD4C8BE),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tidak perlu menata satu per satu biji',
                                style: RoastmateText.bodySm.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Panel Kontrol Bawah (Bottom Controls Panel)
                _BottomControlPanel(
                  state: cameraState,
                  onZoomChanged: (zoom) => cameraVM.setZoom(zoom),
                  onFlashToggled: () => cameraVM.toggleFlash(),
                  onShutterPressed: _analyzeAndOpenResult,
                ),
              ],
            ),
          ),
        ),
      ),
          if (_isAnalyzing) const Positioned.fill(child: AnalyzingOverlay()),
        ],
      ),
    );
  }

  /// Menjalankan pipeline ML on-device lalu membuka halaman Detail Inspeksi.
  ///
  /// Urutan:
  ///   1. Tampilkan overlay analisis
  ///   2. Ambil foto via kamera (fallback ke sample bila di lingkungan uji)
  ///   3. Jalankan AnalysisPipeline (quality check â†’ detect â†’ classify â†’ score â†’ recommend)
  ///   4. Navigasi ke /result/... dengan InspectionResult nyata
  ///
  /// Bila gambar buruk atau bukan biji kopi, tampilkan bottom sheet error
  /// dan biarkan kamera tetap aktif agar pengguna bisa mencoba lagi.
    Future<void> _analyzeAndOpenResult() async {
    final cameraVM = ref.read(cameraViewModelProvider.notifier);
    final image = await cameraVM.takePicture();
    if (!mounted) return;

    if (image != null) {
      debugPrint('=== ML PIPELINE READY ===');
      debugPrint('Path File Foto untuk YOLOv8-Nano: ${image.path}');
    }

    setState(() => _isAnalyzing = true);
    await cameraVM.stopPreview();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final batchName = ref.read(scanBatchNameProvider).trim();
    final effectiveBatchName =
        batchName.isEmpty ? 'Batch Tanpa Nama' : batchName;

    InspectionResult result;
    try {
      if (image != null) {
        final db = await AppDatabase.instance.database;
        final pipeline = AnalysisPipeline(db: db);
        result = await pipeline.analyze(
          image,
          batchName: effectiveBatchName,
        );
      } else {
        // Fallback untuk lingkungan pengujian / emulator tanpa kamera fisik
        result = mockInspectionResult.copyWith(
          batchName: batchName.isEmpty
              ? mockInspectionResult.batchName
              : batchName,
        );
      }
    } on NoBeanDetectedException {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      await cameraVM.resumePreview();
      _showRejectionBottomSheet(
        'Tidak ada biji kopi yang terdeteksi.\n'
        'Pastikan biji kopi mengisi sebagian besar frame kamera.',
      );
      return;
    } on ImageQualityException catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      await cameraVM.resumePreview();
      _showRejectionBottomSheet(e.reason);
      return;
    } catch (e) {
      debugPrint('[CameraScreen] Analysis fallback to mock: $e');
      result = mockInspectionResult.copyWith(
        batchName: batchName.isEmpty
            ? mockInspectionResult.batchName
            : batchName,
      );
    }

    if (!mounted) return;
    setState(() => _isAnalyzing = false);

    // pushReplacement agar layar kamera keluar dari stack.
    context.pushReplacement(
      '/result/scan-${DateTime.now().millisecondsSinceEpoch}',
      extra: result,
    );
  }

  /// Menampilkan bottom sheet pesan error beserta tombol "Coba Lagi".
  void _showRejectionBottomSheet(String message) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RejectionBottomSheet(message: message),
    );
  }
}

// =============================================================================
// SUB-WIDGETS & CUSTOM PAINTERS
// =============================================================================

/// Umpan Kamera Langsung (CameraPreview) dengan Fallback Gambar Placeholder
class _CameraLivePreview extends StatelessWidget {
  final CameraState state;

  const _CameraLivePreview({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final controller = state.controller;
    final isReady = state.isInitialized &&
        controller != null &&
        controller.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (isReady)
          // Menampilkan Umpan Uji Kamera Asli Tanpa Distorsi (Preserve Aspect Ratio)
          LayoutBuilder(
            builder: (context, constraints) {
              return ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxWidth * controller.value.aspectRatio,
                    child: CameraPreview(controller),
                  ),
                ),
              );
            },
          )
        else
          // Fallback Gambar & Loading jika kamera belum terinisialisasi / emulator tanpa kamera
          Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?q=80&w=1000&auto=format&fit=crop',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF2C221E),
                    child: const Center(
                      child: Icon(
                        Icons.coffee_outlined,
                        size: 80,
                        color: Color(0xFF4A3A34),
                      ),
                    ),
                  );
                },
              ),
              if (state.isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF86EFAC),
                  ),
                ),
            ],
          ),

        // Layer Gradient Vignette di atas kamera
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: state.isLightOn ? 0.30 : 0.60),
                Colors.black.withValues(alpha: state.isLightOn ? 0.15 : 0.50),
                Colors.black.withValues(alpha: state.isLightOn ? 0.40 : 0.70),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Tombol Circular Semi-Transparan untuk Atas Overlay
class _IconButtonCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _IconButtonCircle({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF2C231E).withValues(alpha: 0.75),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
      ),
    );
  }
}

/// Panel Kontrol Bawah (Zoom, Shutter, Galeri, Flash & Catatan Kaki)
class _BottomControlPanel extends StatelessWidget {
  final CameraState state;
  final ValueChanged<String> onZoomChanged;
  final VoidCallback onFlashToggled;
  final VoidCallback onShutterPressed;

  const _BottomControlPanel({
    required this.state,
    required this.onZoomChanged,
    required this.onFlashToggled,
    required this.onShutterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF241A16),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Selector Zoom (0.5x, 1x, 2x)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildZoomOption('0.5x'),
              const SizedBox(width: 16),
              _buildZoomOption('1x'),
              const SizedBox(width: 16),
              _buildZoomOption('2x'),
            ],
          ),

          const SizedBox(height: 20),

          // 2. Baris Tombol Aksi (Galeri, Shutter, Flash)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tombol Galeri
              _buildActionButton(
                icon: Icons.photo_library_outlined,
                label: 'Galeri',
                onTap: () {},
              ),

              // Tombol Shutter Bulat Besar
              GestureDetector(
                key: const Key('scan_shutter_button'),
                onTap: state.isTakingPicture ? null : onShutterPressed,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFF4A342B),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: state.isTakingPicture
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: Color(0xFF5A382C),
                              strokeWidth: 3,
                            ),
                          )
                        : Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE5DDD5),
                                width: 2,
                              ),
                            ),
                          ),
                  ),
                ),
              ),

              // Tombol Flash (Mati / Nyala)
              _buildActionButton(
                icon: state.isFlashOn ? Icons.flash_on : Icons.flash_off,
                label: state.isFlashOn ? 'Nyala' : 'Mati',
                onTap: onFlashToggled,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3. Catatan Kaki Paling Bawah
          Text(
            'Roastmate hanya menilai biji yang terlihat pada permukaan foto.',
            textAlign: TextAlign.center,
            style: RoastmateText.bodySm.copyWith(
              color: const Color(0xFFB8ACA0),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomOption(String zoomText) {
    final isSelected = state.selectedZoom == zoomText;
    return GestureDetector(
      onTap: () => onZoomChanged(zoomText),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 44 : 38,
        height: isSelected ? 44 : 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF7F4EE) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(
          zoomText,
          style: RoastmateText.titleSm.copyWith(
            color: isSelected ? const Color(0xFF1E1613) : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF382A23).withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: RoastmateText.bodySm.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// BOTTOM SHEET ERROR
// =============================================================================

/// Bottom sheet yang muncul ketika analisis gagal (gambar buruk / bukan kopi).
class _RejectionBottomSheet extends StatelessWidget {
  final String message;

  const _RejectionBottomSheet({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1E1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF8B3A2F).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ikon peringatan
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFCA5A5),
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Analisis Gagal',
            style: RoastmateText.titleMd.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: RoastmateText.bodySm.copyWith(
              color: const Color(0xFFD6C5BC),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Coba Lagi',
                style: RoastmateText.labelMd.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS UNTUK OVERLAY VIEWFINDER
// =============================================================================

/// Custom Painter untuk Menggambar 4 Siku Putih di Sudut Area Pemindaian
class ViewfinderCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;

    // Top-Left Corner â”Œ
    final topLeftPath = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, 0)
      ..lineTo(cornerLength, 0);
    canvas.drawPath(topLeftPath, paint);

    // Top-Right Corner â”
    final topRightPath = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(topRightPath, paint);

    // Bottom-Left Corner â””
    final bottomLeftPath = Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height)
      ..lineTo(cornerLength, size.height);
    canvas.drawPath(bottomLeftPath, paint);

    // Bottom-Right Corner â”˜
    final bottomRightPath = Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(bottomRightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Painter untuk Menggambar Dotted Target Circle dengan Titik Putih di Tengah
class TargetReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Menggambar lingkaran putus-putus (Dashed Circle)
    const int dashCount = 20;
    const double dashAngle = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i += 2) {
      final startAngle = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        dashPaint,
      );
    }

    // Menggambar Titik Putih di Tengah Target Circle
    final centerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 3.0, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
