import 'package:flutter/material.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../../domain/entities/onboarding_slide.dart';

/// Widget showcase interaktif yang merepresentasikan mock-up visual fitur
/// sesuai prinsip Warm Technical Minimalism (docs/DESIGN.md).
class OnboardingVisualShowcase extends StatelessWidget {
  final OnboardingSlideType type;

  const OnboardingVisualShowcase({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 230,
      padding: const EdgeInsets.all(RoastmateSpacing.lg),
      decoration: BoxDecoration(
        color: RoastmateColors.surface,
        borderRadius: BorderRadius.circular(RoastmateRadius.large),
        border: Border.all(color: RoastmateColors.borderDefault, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(43, 36, 33, 0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (type) {
      case OnboardingSlideType.authOffline:
        return const _AuthOfflineVisual();
      case OnboardingSlideType.cameraScan:
        return const _CameraScanVisual();
      case OnboardingSlideType.inspectionRoast:
        return const _InspectionRoastVisual();
      case OnboardingSlideType.dashboardHistory:
        return const _DashboardHistoryVisual();
      case OnboardingSlideType.brewRecipes:
        return const _BrewRecipesVisual();
      case OnboardingSlideType.cloudSync:
        return const _CloudSyncVisual();
    }
  }
}

// ============================================================
// 1. VISUAL: AUTENTIKASI & MODE OFFLINE
// ============================================================
class _AuthOfflineVisual extends StatelessWidget {
  const _AuthOfflineVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('auth_offline_visual'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatusCard(
                icon: Icons.storage_rounded,
                iconColor: RoastmateColors.tertiary,
                title: 'SQLite Lokal',
                status: 'Aktif Mandiri',
                statusColor: RoastmateColors.statusSuccess,
                bgColor: const Color(0xFFF0F5EC),
              ),
            ),
            const SizedBox(width: RoastmateSpacing.md),
            Expanded(
              child: _StatusCard(
                icon: Icons.cloud_outlined,
                iconColor: RoastmateColors.statusInfo,
                title: 'Supabase Cloud',
                status: 'Opsi Akun Online',
                statusColor: RoastmateColors.statusInfo,
                bgColor: RoastmateColors.statusInfoContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: RoastmateSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RoastmateSpacing.md,
            vertical: RoastmateSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: RoastmateColors.surfaceContainer,
            borderRadius: BorderRadius.circular(RoastmateRadius.small),
            border: Border.all(color: RoastmateColors.borderDefault),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 18,
                color: RoastmateColors.statusSuccess,
              ),
              const SizedBox(width: RoastmateSpacing.sm),
              Expanded(
                child: Text(
                  'Siap dipakai tanpa koneksi di kebun & roastery',
                  style: RoastmateText.bodySm.copyWith(
                    color: RoastmateColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 2. VISUAL: INPUT NAMA BATCH & KAMERA SCAN
// ============================================================
class _CameraScanVisual extends StatelessWidget {
  const _CameraScanVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('camera_scan_visual'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mini dialog setup nama kopi
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RoastmateSpacing.md,
            vertical: RoastmateSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: RoastmateColors.surfaceContainer,
            borderRadius: BorderRadius.circular(RoastmateRadius.small),
            border: Border.all(color: RoastmateColors.primary, width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.edit_note,
                size: 18,
                color: RoastmateColors.primary,
              ),
              const SizedBox(width: RoastmateSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nama Jenis Biji Kopi',
                      style: RoastmateText.labelSm.copyWith(
                        color: RoastmateColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'Arabica Gayo Wine Anaerob',
                      style: RoastmateText.bodySm.copyWith(
                        color: RoastmateColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: RoastmateColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: RoastmateSpacing.sm),
        // Mini viewfinder simulation
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: RoastmateColors.surfaceInverse,
              borderRadius: BorderRadius.circular(RoastmateRadius.small),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Corner indicators
                Positioned(
                  top: 8,
                  left: 12,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 2),
                        left: BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 12,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white, width: 2),
                        right: BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wb_sunny_outlined,
                      size: 16,
                      color: RoastmateColors.terracottaSoft,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pencahayaan Baik • Siap Foto',
                      style: RoastmateText.labelSm.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: RoastmateColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 3. VISUAL: HASIL INSPEKSI & TINGKAT SANGRAI
// ============================================================
class _InspectionRoastVisual extends StatelessWidget {
  const _InspectionRoastVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('inspection_roast_visual'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Grade Banner
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RoastmateSpacing.md,
            vertical: RoastmateSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE0EADF),
            borderRadius: BorderRadius.circular(RoastmateRadius.small),
            border: Border.all(color: RoastmateColors.statusSuccess),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GRADE INDIKATIF — SPECIALTY',
                style: RoastmateText.labelSm.copyWith(
                  color: RoastmateColors.statusSuccess,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Skor: 88.5 / 100',
                style: RoastmateText.labelSm.copyWith(
                  color: RoastmateColors.statusSuccess,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: RoastmateSpacing.sm),
        // 4 Defect Chips
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _MiniDefectBadge(label: 'Normal', count: 96, color: Color(0xFF5E6B4A)),
            _MiniDefectBadge(label: 'Quaker', count: 2, color: Color(0xFFC49038)),
            _MiniDefectBadge(label: 'Broken', count: 1, color: Color(0xFF9B6A3D)),
            _MiniDefectBadge(label: 'Severe', count: 1, color: Color(0xFFB54A43)),
          ],
        ),
        const SizedBox(height: RoastmateSpacing.sm),
        // Roast Spectrum Bar
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RoastmateSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: RoastmateColors.surfaceContainer,
            borderRadius: BorderRadius.circular(RoastmateRadius.small),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _RoastPill(label: 'Green', isSelected: false),
              _RoastPill(label: 'Light', isSelected: false),
              _RoastPill(label: 'Medium', isSelected: true),
              _RoastPill(label: 'Dark', isSelected: false),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 4. VISUAL: DASBOR BERANDA & RIWAYAT
// ============================================================
class _DashboardHistoryVisual extends StatelessWidget {
  const _DashboardHistoryVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('dashboard_history_visual'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Metric Counters Row
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                title: 'Total Batch',
                value: '24',
                color: RoastmateColors.primary,
              ),
            ),
            const SizedBox(width: RoastmateSpacing.sm),
            Expanded(
              child: _MetricTile(
                title: 'Rata-rata Skor',
                value: '86.4',
                color: RoastmateColors.statusSuccess,
              ),
            ),
            const SizedBox(width: RoastmateSpacing.sm),
            Expanded(
              child: _MetricTile(
                title: 'Arabica',
                value: '75%',
                color: RoastmateColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: RoastmateSpacing.sm),
        // History List Sample with Filter & Delete Icon
        Container(
          padding: const EdgeInsets.all(RoastmateSpacing.sm),
          decoration: BoxDecoration(
            color: RoastmateColors.surfaceContainer,
            borderRadius: BorderRadius.circular(RoastmateRadius.small),
            border: Border.all(color: RoastmateColors.borderDefault),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: RoastmateColors.primary,
                  borderRadius: BorderRadius.circular(RoastmateRadius.micro),
                ),
                child: const Icon(Icons.coffee, size: 18, color: Colors.white),
              ),
              const SizedBox(width: RoastmateSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kintamani Natural • 85.0',
                      style: RoastmateText.labelSm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Tersimpan di SQLite • Filter: Arabica',
                      style: RoastmateText.bodySm.copyWith(
                        color: RoastmateColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.delete_outline,
                size: 18,
                color: RoastmateColors.iconMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 5. VISUAL: KATALOG METODE & RESEP KUSTOM
// ============================================================
class _BrewRecipesVisual extends StatelessWidget {
  const _BrewRecipesVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('brew_recipes_visual'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Curated Recipe Card
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RoastmateSpacing.md,
            vertical: RoastmateSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: RoastmateColors.surfaceContainer,
            borderRadius: BorderRadius.circular(RoastmateRadius.small),
            border: Border.all(color: RoastmateColors.primary, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: RoastmateColors.primary,
                  borderRadius: BorderRadius.circular(RoastmateRadius.micro),
                ),
                child: const Icon(
                  Icons.coffee_maker_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: RoastmateSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'V60 Pour Over (Rekomendasi)',
                      style: RoastmateText.labelSm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: RoastmateColors.primary,
                      ),
                    ),
                    Text(
                      '15g Biji : 225ml Air • 92°C • Medium Grind',
                      style: RoastmateText.bodySm.copyWith(
                        color: RoastmateColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: RoastmateSpacing.sm),
        // Custom Recipe Add Action
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RoastmateSpacing.md,
            vertical: RoastmateSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: RoastmateColors.terracottaSoft,
            borderRadius: BorderRadius.circular(RoastmateRadius.small),
            border: Border.all(color: RoastmateColors.secondary),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                size: 16,
                color: RoastmateColors.secondary,
              ),
              const SizedBox(width: RoastmateSpacing.xs),
              Text(
                'Buat & Simpan Resep Seduh Kustom Anda',
                style: RoastmateText.labelSm.copyWith(
                  color: RoastmateColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 6. VISUAL: SINKRONISASI CLOUD & FOTO
// ============================================================
class _CloudSyncVisual extends StatelessWidget {
  const _CloudSyncVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('cloud_sync_visual'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: _SyncRow(
                icon: Icons.sync_alt_rounded,
                title: 'Data Batch & Resep',
                target: 'Supabase Cloud',
                color: RoastmateColors.statusSuccess,
                statusText: 'Tersinkron',
              ),
            ),
            const SizedBox(width: RoastmateSpacing.sm),
            Expanded(
              child: _SyncRow(
                icon: Icons.image_outlined,
                title: 'Sampel Foto Biji',
                target: 'Cloudinary CDN',
                color: RoastmateColors.statusInfo,
                statusText: 'Auto-Upload',
              ),
            ),
          ],
        ),
        const SizedBox(height: RoastmateSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RoastmateSpacing.md,
            vertical: RoastmateSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: RoastmateColors.surfaceContainer,
            borderRadius: BorderRadius.circular(RoastmateRadius.small),
            border: Border.all(color: RoastmateColors.borderDefault),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: RoastmateColors.secondary,
              ),
              const SizedBox(width: RoastmateSpacing.sm),
              Expanded(
                child: Text(
                  'Antrean retry cerdas: data aman saat jaringan terputus',
                  style: RoastmateText.bodySm.copyWith(
                    color: RoastmateColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// HELPER REUSABLE SUB-WIDGETS
// ============================================================
class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String status;
  final Color statusColor;
  final Color bgColor;

  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RoastmateSpacing.sm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(RoastmateRadius.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 4),
          Text(
            title,
            style: RoastmateText.labelSm.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            status,
            style: RoastmateText.bodySm.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDefectBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _MiniDefectBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(RoastmateRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: $count',
            style: RoastmateText.labelSm.copyWith(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoastPill extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _RoastPill({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? RoastmateColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(RoastmateRadius.micro),
      ),
      child: Text(
        label,
        style: RoastmateText.labelSm.copyWith(
          color: isSelected ? Colors.white : RoastmateColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: RoastmateColors.surfaceContainer,
        borderRadius: BorderRadius.circular(RoastmateRadius.small),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: RoastmateText.labelSm.copyWith(
              fontSize: 10,
              color: RoastmateColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: RoastmateText.titleMd.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String target;
  final Color color;
  final String statusText;

  const _SyncRow({
    required this.icon,
    required this.title,
    required this.target,
    required this.color,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RoastmateSpacing.sm),
      decoration: BoxDecoration(
        color: RoastmateColors.surfaceContainer,
        borderRadius: BorderRadius.circular(RoastmateRadius.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: color),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(RoastmateRadius.full),
                ),
                child: Text(
                  statusText,
                  style: RoastmateText.labelSm.copyWith(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: RoastmateText.labelSm.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            target,
            style: RoastmateText.bodySm.copyWith(
              fontSize: 10,
              color: RoastmateColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
