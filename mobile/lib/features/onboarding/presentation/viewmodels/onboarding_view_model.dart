import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../domain/entities/onboarding_slide.dart';
import '../../domain/repositories/onboarding_repository.dart';

/// Provider repositori onboarding.
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl();
});

/// State untuk alur onboarding.
class OnboardingState {
  final int currentIndex;
  final bool isCompleted;
  final List<OnboardingSlide> slides;

  const OnboardingState({
    required this.currentIndex,
    required this.isCompleted,
    required this.slides,
  });

  bool get isFirstPage => currentIndex == 0;
  bool get isLastPage => currentIndex == slides.length - 1;
  OnboardingSlide get currentSlide => slides[currentIndex];

  OnboardingState copyWith({
    int? currentIndex,
    bool? isCompleted,
    List<OnboardingSlide>? slides,
  }) {
    return OnboardingState(
      currentIndex: currentIndex ?? this.currentIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      slides: slides ?? this.slides,
    );
  }
}

/// ViewModel untuk mengelola alur slide dan persistensi onboarding.
class OnboardingViewModel extends StateNotifier<OnboardingState> {
  final OnboardingRepository _repository;

  OnboardingViewModel(this._repository)
      : super(
          OnboardingState(
            currentIndex: 0,
            isCompleted: false,
            slides: _defaultSlides,
          ),
        );

  static const List<OnboardingSlide> _defaultSlides = [
    OnboardingSlide(
      id: 'auth_offline',
      type: OnboardingSlideType.authOffline,
      categoryBadge: 'ARSITEKTUR OFFLINE-FIRST',
      title: 'Autentikasi & Fleksibilitas Akses',
      description:
          'Gunakan aplikasi kapan saja di kebun, gudang, maupun roastery tanpa bergantung pada jaringan internet. '
          'Basis data lokal SQLite siap bekerja mandiri, dan Anda dapat menghubungkan akun Supabase saat online untuk cadangan cloud.',
      highlights: [
        'Basis Data SQLite Lokal Mandiri',
        'Akses Fitur Penuh Tanpa Sinyal',
        'Sinkronisasi Akun Cloud Otomatis',
      ],
      icon: Icons.offline_bolt_outlined,
      accentColor: RoastmateColors.tertiary,
    ),
    OnboardingSlide(
      id: 'camera_scan',
      type: OnboardingSlideType.cameraScan,
      categoryBadge: 'ALUR PEMINDAIAN FISIK',
      title: 'Input Nama Batch & Kamera Presisi',
      description:
          'Beri identitas nama biji kopi sebelum membuka kamera. Bidik sampel biji menggunakan panduan viewfinder bergaris siku '
          'dan indikator pencahayaan, lalu simpan foto dan metadata secara otomatis ke basis data SQLite.',
      highlights: [
        'Setup Nama Kopi Sebelum Scan',
        'Viewfinder Garis Siku & Pencahayaan',
        'Penyimpanan Terintegrasi ke SQLite',
      ],
      icon: Icons.camera_alt_outlined,
      accentColor: RoastmateColors.primary,
    ),
    OnboardingSlide(
      id: 'inspection_roast',
      type: OnboardingSlideType.inspectionRoast,
      categoryBadge: 'KLASIFIKASI ON-DEVICE ML',
      title: 'Skor Kualitas & Tingkat Sangrai',
      description:
          'Dapatkan skor kualitas objektif dan grade indikatif standar industri. '
          'Model cerdas mengklasifikasi 4 kelas defect (Normal, Quaker, Broken, Severe) serta spektrum tingkat sangrai dari Green hingga Dark.',
      highlights: [
        'Skor Kualitas & Grade Indikatif',
        'Deteksi 4 Kelas Defect Biji',
        'Spektrum Sangrai (Green, Light, Medium, Dark)',
      ],
      icon: Icons.verified_outlined,
      accentColor: RoastmateColors.statusSuccess,
    ),
    OnboardingSlide(
      id: 'dashboard_history',
      type: OnboardingSlideType.dashboardHistory,
      categoryBadge: 'MONITORING & ARSIP',
      title: 'Dasbor Beranda & Manajemen Riwayat',
      description:
          'Pantau rasio spesies (Arabica, Robusta, Liberika), sebaran defect, dan rata-rata skor pada Beranda. '
          'Telusuri arsip riwayat dengan filter spesies terstruktur dan kelola penghapusan data secara aman.',
      highlights: [
        'Ringkasan Rasio Spesies & Skor Rata-rata',
        'Filter Riwayat Sesuai Kategori Spesies',
        'Kontrol Manajemen & Penghapusan Arsip',
      ],
      icon: Icons.bar_chart_rounded,
      accentColor: RoastmateColors.secondary,
    ),
    OnboardingSlide(
      id: 'brew_recipes',
      type: OnboardingSlideType.brewRecipes,
      categoryBadge: 'RITUAL PENYEDUHAN',
      title: 'Katalog Metode & Resep Kustom',
      description:
          'Jelajahi panduan penyeduhan terkurasi (V60, Aeropress, French Press) yang direkomendasikan otomatis sesuai profil sangrai biji Anda. '
          'Anda juga bebas meracik, menyimpan, dan menyeduh dengan resep kustom pribadi.',
      highlights: [
        'Panduan Metode Seduh Terkurasi',
        'Rekomendasi Cerdas Berdasarkan Hasil Scan',
        'Buat & Simpan Resep Seduh Kustom',
      ],
      icon: Icons.coffee_outlined,
      accentColor: RoastmateColors.primary,
    ),
    OnboardingSlide(
      id: 'cloud_sync',
      type: OnboardingSlideType.cloudSync,
      categoryBadge: 'CADANGAN CLOUD TERPADU',
      title: 'Sinkronisasi Cloud & Cadangan Foto',
      description:
          'Data lokal Anda aman terlindungi. Saat perangkat terhubung ke internet, sinkronisasi dua arah menyelaraskan riwayat inspeksi '
          'dan resep ke Supabase, serta mengunggah sampel foto ke Cloudinary dengan antrean pengulangan (retry).',
      highlights: [
        'Sinkron Dua Arah Aman Saat Online',
        'Upload Foto Otomatis ke Cloudinary',
        'Sistem Antrean Retry Saat Jaringan Pulih',
      ],
      icon: Icons.cloud_sync_outlined,
      accentColor: RoastmateColors.statusInfo,
    ),
  ];

  void setPage(int index) {
    if (index >= 0 && index < state.slides.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  void nextPage() {
    if (!state.isLastPage) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previousPage() {
    if (!state.isFirstPage) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  Future<void> completeOnboarding() async {
    await _repository.setOnboardingCompleted(true);
    state = state.copyWith(isCompleted: true);
  }
}

/// Provider state onboarding.
final onboardingViewModelProvider =
    StateNotifierProvider<OnboardingViewModel, OnboardingState>((ref) {
  final repo = ref.watch(onboardingRepositoryProvider);
  return OnboardingViewModel(repo);
});
