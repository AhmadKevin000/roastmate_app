import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';

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
  final XFile? capturedImage;

  /// Nama jenis biji kopi yang diinputkan pengguna.
  final String coffeeName;

  /// Menandakan proses penyimpanan ke database SQLite sedang berjalan.
  final bool isSaving;

  /// ID baris record analisis yang baru saja berhasil disimpan ke SQLite.
  final int? lastSavedAnalysisId;

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
    this.coffeeName = '',
    this.isSaving = false,
    this.lastSavedAnalysisId,
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
    String? coffeeName,
    bool? isSaving,
    int? lastSavedAnalysisId,
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
      coffeeName: coffeeName ?? this.coffeeName,
      isSaving: isSaving ?? this.isSaving,
      lastSavedAnalysisId: lastSavedAnalysisId ?? this.lastSavedAnalysisId,
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

  /// Mengatur nama kopi yang akan disimpan.
  void setCoffeeName(String name) {
    state = state.copyWith(coffeeName: name);
  }

  /// Menyimpan hasil foto dan nama kopi ke database SQLite lokal via [AppDatabase].
  ///
  /// Menggunakan tabel `analyses` yang telah dikonfigurasikan di database backend.
  Future<int?> saveCapturedAnalysis({
    required String imagePath,
    String? customName,
  }) async {
    final name = (customName != null && customName.trim().isNotEmpty)
        ? customName.trim()
        : (state.coffeeName.trim().isNotEmpty ? state.coffeeName.trim() : 'Kopi Tanpa Nama');

    try {
      state = state.copyWith(isSaving: true, errorMessage: null);

      // Membuka database SQLite melalui instance singleton yang sudah disiapkan rekan
      final db = await AppDatabase.instance.database;

      // Klasifikasi jenis spesies dasar berdasarkan teks nama kopi yang diinputkan
      String species = 'Mixed';
      final lower = name.toLowerCase();
      if (lower.contains('arabica') || lower.contains('arabika')) {
        species = 'Arabica';
      } else if (lower.contains('robusta')) {
        species = 'Robusta';
      }

      final row = <String, Object?>{
        'created_at': DateTime.now().toIso8601String(),
        'image_path': imagePath,
        'species': species,
        'roast': 'Medium',
        'roast_confidence': 1.0,
        'roast_distribution': jsonEncode({
          'coffee_name': name,
          'saved_from': 'camera_scan',
        }),
        'visible_beans': 0,
        'defect_rate': 0.0,
        'quality_score': 85,
        'quality_profile': 'High',
      };

      final insertedId = await db.insert('analyses', row);

      state = state.copyWith(
        isSaving: false,
        lastSavedAnalysisId: insertedId,
      );

      debugPrint('=== DATABASE INSERT SUCCESS ===');
      debugPrint('Berhasil menyimpan record analisis ke SQLite!');
      debugPrint('ID: $insertedId | Nama: $name | Path: $imagePath');
      debugPrint('===============================');

      return insertedId;
    } catch (e) {
      debugPrint('Gagal menyimpan record ke SQLite: $e');
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Gagal menyimpan ke database: ${e.toString()}',
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

/// Provider state untuk nama kopi yang diinputkan pengguna sebelum membuka kamera.
final coffeeNameProvider = StateProvider<String>((ref) => '');

/// Riverpod StateNotifierProvider untuk ViewModel Kamera.
final cameraViewModelProvider =
    StateNotifierProvider.autoDispose<CameraViewModel, CameraState>((ref) {
  return CameraViewModel();
});
