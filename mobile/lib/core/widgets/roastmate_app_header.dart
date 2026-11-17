import 'package:flutter/material.dart';

import '../theme/roastmate_colors.dart';
import '../theme/roastmate_radius.dart';
import '../theme/roastmate_spacing.dart';
import '../theme/roastmate_text.dart';

/// Header brand yang konsisten untuk layar bertab (Beranda, Analisis, Seduh).
///
/// Dirender sebagai [AppBar] sehingga tetap menempel di atas saat konten
/// di-scroll (sama seperti layar detail). Menampilkan logo aplikasi, nama
/// "Roastmate", sublabel tab aktif, ikon tambah (opsional), dan ikon
/// pengaturan. Tidak memakai avatar.
class RoastmateAppHeader extends StatelessWidget
    implements PreferredSizeWidget {
  /// Sublabel tab aktif (mis. "Beranda", "Analisis", "Seduh").
  final String subtitle;

  final VoidCallback? onSettings;

  /// Callback tombol tambah (opsional — hanya tab Seduh yang memakainya).
  final VoidCallback? onAdd;

  /// Tinggi area toolbar (tanpa inset status bar).
  static const double toolbarHeight = 64;

  const RoastmateAppHeader({
    super.key,
    required this.subtitle,
    this.onSettings,
    this.onAdd,
  });

  @override
  Size get preferredSize => const Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: RoastmateColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: toolbarHeight,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(RoastmateRadius.small),
            ),
            child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
          ),
          const SizedBox(width: RoastmateSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Roastmate',
                style: RoastmateText.titleMd.copyWith(
                  color: RoastmateColors.primary,
                ),
              ),
              Text(
                subtitle,
                style: RoastmateText.bodySm.copyWith(
                  color: RoastmateColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (onAdd != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: onAdd,
              icon: const Icon(
                Icons.add,
                color: RoastmateColors.primary,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: onSettings,
            icon: const Icon(
              Icons.settings_outlined,
              color: RoastmateColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
