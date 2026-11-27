import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../viewmodels/onboarding_view_model.dart';
import '../widgets/onboarding_slide_card.dart';

/// Layar utama alur Onboarding RoastMate App.
///
/// Menyajikan panduan 6 pilar fitur utama:
/// 1. Autentikasi & Mode Offline
/// 2. Input Nama Batch & Pemindaian Kamera (Camera Scan)
/// 3. Hasil Inspeksi & Klasifikasi Tingkat Sangrai
/// 4. Dasbor Beranda & Riwayat Analisis
/// 5. Katalog & Resep Seduh Kustom
/// 6. Sinkronisasi Cloud & Cadangan Foto
///
/// Mendukung:
/// - Swipe antar-slide (PageView)
/// - Tombol "Lewati" (Skip)
/// - Navigasi "Sebelumnya" & "Lanjut"
/// - Tombol "Mulai Sekarang" di slide terakhir
/// - Penyimpanan status selesai permanen ke SQLite via Riverpod
class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialPage = ref.read(onboardingViewModelProvider).currentIndex;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    await ref.read(onboardingViewModelProvider.notifier).completeOnboarding();
    AuthGateListenable.instance.updateOnboarding(true);

    if (!mounted) return;

    if (context.canPop()) {
      context.pop();
      return;
    }

    final auth = AuthGateListenable.instance.authState;
    final loggedIn = auth?.loggedIn ?? false;
    final unavailable = auth?.unavailable ?? false;

    if (loggedIn || unavailable) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  void _onNextPressed(int currentIndex, int totalPages) {
    if (currentIndex < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _onPrevPressed(int currentIndex) {
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingViewModelProvider);
    final slides = state.slides;
    final currentIndex = state.currentIndex;
    final isLastPage = state.isLastPage;

    return Scaffold(
      backgroundColor: RoastmateColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // TOP HEADER: BRANDING & TOMBOL LEWATI (SKIP)
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RoastmateSpacing.lg,
                vertical: RoastmateSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: RoastmateColors.primary,
                          borderRadius: BorderRadius.circular(
                            RoastmateRadius.small,
                          ),
                        ),
                        child: const Icon(
                          Icons.coffee_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: RoastmateSpacing.sm),
                      Text(
                        'RoastMate',
                        style: RoastmateText.titleMd.copyWith(
                          color: RoastmateColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  if (!isLastPage)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: RoastmateColors.textSecondary,
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: RoastmateSpacing.md,
                        ),
                      ),
                      onPressed: _finishOnboarding,
                      child: Text(
                        'Lewati',
                        style: RoastmateText.labelLg.copyWith(
                          color: RoastmateColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48, width: 64),
                ],
              ),
            ),

            // ==========================================
            // SLIDE CONTENT: PAGE VIEW
            // ==========================================
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (index) {
                  ref
                      .read(onboardingViewModelProvider.notifier)
                      .setPage(index);
                },
                itemBuilder: (context, index) {
                  return OnboardingSlideCard(slide: slides[index]);
                },
              ),
            ),

            // ==========================================
            // BOTTOM BAR: INDICATOR & ACTION BUTTONS
            // ==========================================
            Container(
              padding: const EdgeInsets.fromLTRB(
                RoastmateSpacing.lg,
                RoastmateSpacing.sm,
                RoastmateSpacing.lg,
                RoastmateSpacing.lg,
              ),
              decoration: const BoxDecoration(
                color: RoastmateColors.background,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (index) {
                      final isActive = index == currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 7,
                        width: isActive ? 24 : 7,
                        decoration: BoxDecoration(
                          color: isActive
                              ? RoastmateColors.primary
                              : RoastmateColors.borderStrong.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(
                            RoastmateRadius.full,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: RoastmateSpacing.md),

                  // Action Buttons Row
                  Row(
                    children: [
                      // Tombol Sebelumnya (Hanya jika bukan slide pertama)
                      if (currentIndex > 0) ...[
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              side: const BorderSide(
                                color: RoastmateColors.borderStrong,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  RoastmateRadius.small,
                                ),
                              ),
                            ),
                            onPressed: () => _onPrevPressed(currentIndex),
                            child: Text(
                              'Kembali',
                              style: RoastmateText.labelLg.copyWith(
                                color: RoastmateColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: RoastmateSpacing.sm),
                      ],

                      // Tombol Lanjut atau Mulai Sekarang
                      Expanded(
                        flex: currentIndex > 0 ? 3 : 1,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RoastmateColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                RoastmateRadius.small,
                              ),
                            ),
                          ),
                          onPressed: () =>
                              _onNextPressed(currentIndex, slides.length),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLastPage ? 'Mulai Sekarang' : 'Lanjut',
                                style: RoastmateText.labelLg.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                isLastPage
                                    ? Icons.rocket_launch_outlined
                                    : Icons.arrow_forward_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
