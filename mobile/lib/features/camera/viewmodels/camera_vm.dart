import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State immutable untuk fitur Kamera.
@immutable
class CameraState {
  final bool isInitialized;
  final bool isLoading;
  final bool isTakingPicture;
  final String? errorMessage;
  final CameraController? controller;
  final bool isFlashOn;
  final bool isLightOn;
  final String selectedZoom;
  final double currentZoom;
  final double maxZoom;
  final double minZoom;
  
  /// File foto yang berhasil diambil oleh kamera.
  /// CATATAN UNTUK TIM MACHINE LEARNING:
  /// Gunakan `capturedImage?.path` untuk mendapatkan path file lokal gambar
  /// hasil jepretan kamera yang siap di-input ke dalam model YOLOv8-Nano.
  final XFile? capturedImage;

  const CameraState({
    this.isInitialized = false,
    this.isLoading = true,
    this.isTakingPicture = false,
    this.errorMessage,
    this.controller,
    this.isFlashOn = false,
    this.isLightOn = true,
    this.selectedZoom = '1x',
    this.currentZoom = 1.0,
    this.maxZoom = 1.0,
    this.minZoom = 1.0,
    this.capturedImage,
  });

  CameraState copyWith({
    bool? isInitialized,
    bool? isLoading,
    bool? isTakingPicture,
    String? errorMessage,
    CameraController? controller,
    bool? isFlashOn,
    bool? isLightOn,
    String? selectedZoom,
    double? currentZoom,
    double? maxZoom,
    double? minZoom,
    XFile? capturedImage,
  }) {
    return CameraState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      isTakingPicture: isTakingPicture ?? this.isTakingPicture,
      errorMessage: errorMessage,
      controller: controller ?? this.controller,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      isLightOn: isLightOn ?? this.isLightOn,
      selectedZoom: selectedZoom ?? this.selectedZoom,
      currentZoom: currentZoom ?? this.currentZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      minZoom: minZoom ?? this.minZoom,
      capturedImage: capturedImage ?? this.capturedImage,
    );
  }
}

/// ViewModel untuk mengelola state dan logika bisnis kamera (MVVM).
class CameraViewModel extends StateNotifier<CameraState> {
  List<CameraDescription> _cameras = [];

  CameraViewModel() : super(const CameraState()) {
    initCamera();
  }

  /// Menginisialisasi kamera perangkat (Pilih Kamera Belakang).
  Future<void> initCamera() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isInitialized: false,
          errorMessage: 'Tidak ada kamera yang terdeteksi di perangkat ini.',
        );
        return;
      }

      // Cari kamera belakang
      final backCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      double minZoom = 1.0;
      double maxZoom = 1.0;
      try {
        minZoom = await controller.getMinZoomLevel();
        maxZoom = await controller.getMaxZoomLevel();
      } catch (_) {}

      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
        controller: controller,
        minZoom: minZoom,
        maxZoom: maxZoom,
        currentZoom: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: false,
        errorMessage: 'Gagal menginisialisasi kamera: ${e.toString()}',
      );
    }
  }

  /// Mengubah tingkat Zoom Kamera ('0.5x', '1x', '2x').
  Future<void> setZoom(String zoomLabel) async {
    final controller = state.controller;
    if (controller == null || !state.isInitialized) return;

    double targetZoom = 1.0;
    if (zoomLabel == '0.5x') {
      targetZoom = state.minZoom;
    } else if (zoomLabel == '2x') {
      targetZoom = (state.maxZoom >= 2.0) ? 2.0 : state.maxZoom;
    } else {
      targetZoom = 1.0;
    }

    try {
      await controller.setZoomLevel(targetZoom);
      state = state.copyWith(
        selectedZoom: zoomLabel,
        currentZoom: targetZoom,
      );
    } catch (e) {
      debugPrint('Error setting zoom: $e');
    }
  }

  /// Menyalakan / Mematikan Flash (Torch Mode).
  Future<void> toggleFlash() async {
    final controller = state.controller;
    if (controller == null || !state.isInitialized) return;

    final nextFlashState = !state.isFlashOn;
    try {
      await controller.setFlashMode(
        nextFlashState ? FlashMode.torch : FlashMode.off,
      );
      state = state.copyWith(isFlashOn: nextFlashState);
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  /// Menyalakan / Mematikan Lampu UI Pencerah Viewfinder.
  void toggleLight() {
    state = state.copyWith(isLightOn: !state.isLightOn);
  }

  // ===========================================================================
  // CATATAN PENTING UNTUK TIM MACHINE LEARNING (YOLOv8-Nano Integration):
  // ===========================================================================
  // Method `takePicture()` di bawah ini mengambil foto biji kopi dari kamera.
  //
  // CARA MENGAMBIL PATH HASIL FOTO:
  // 1. Panggil `final imageFile = await ref.read(cameraViewModelProvider.notifier).takePicture();`
  // 2. Akses path file menggunakan: `imageFile.path` (contoh: '/data/user/0/.../CAP_xxx.jpg')
  // 3. Masukkan `File(imageFile.path)` langsung ke dalam pipeline pra-pemrosesan model ML YOLOv8.
  // ===========================================================================
  Future<XFile?> takePicture() async {
    final controller = state.controller;
    if (controller == null || !state.isInitialized || state.isTakingPicture) {
      return null;
    }

    try {
      state = state.copyWith(isTakingPicture: true);

      // Mengambil gambar dari umpan langsung kamera
      final XFile image = await controller.takePicture();

      state = state.copyWith(
        isTakingPicture: false,
        capturedImage: image,
      );

      debugPrint('=== ML PIPELINE READY ===');
      debugPrint('Foto Biji Kopi Berhasil Diambil!');
      debugPrint('Path File Foto untuk YOLOv8-Nano: ${image.path}');
      debugPrint('=========================');

      return image;
    } catch (e) {
      state = state.copyWith(
        isTakingPicture: false,
        errorMessage: 'Gagal mengambil foto: ${e.toString()}',
      );
      return null;
    }
  }

  @override
  void dispose() {
    state.controller?.dispose();
    super.dispose();
  }
}

/// Riverpod StateNotifierProvider untuk ViewModel Kamera.
final cameraViewModelProvider =
    StateNotifierProvider.autoDispose<CameraViewModel, CameraState>((ref) {
  return CameraViewModel();
});
