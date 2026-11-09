import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/roastmate_colors.dart';
import '../theme/roastmate_text.dart';

/// AppBar konsisten untuk layar yang di-push (Scan, Setup Scan, Detail
/// Inspeksi, Detail Resep).
///
/// Tombol kembali + judul di tengah. Tidak memakai avatar.
class RoastmateAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const RoastmateAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: RoastmateColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: RoastmateColors.textPrimary),
        onPressed: () {
          if (context.canPop()) context.pop();
        },
      ),
      title: Text(
        title,
        style: RoastmateText.titleLg.copyWith(
          color: RoastmateColors.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }
}
