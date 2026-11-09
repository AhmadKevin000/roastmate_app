import 'package:flutter/material.dart';

/// Overlay "Menganalisis biji kopi…" saat simulasi pipeline ML berjalan.
///
/// Dipakai sebagai child `Positioned.fill` di dalam `Stack`.
class AnalyzingOverlay extends StatelessWidget {
  const AnalyzingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC231A16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                color: Color(0xFF86EFAC),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Menganalisis biji kopi…',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Menjalankan model computer vision',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
