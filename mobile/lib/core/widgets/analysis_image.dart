import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/roastmate_colors.dart';

/// Sisip transformasi resize `c_fill` ke URL delivery Cloudinary.
///
/// Mengembalikan URL lengkap dengan transformasi
/// (`.../image/upload/c_fill,w_200,h_200/<public_id>`) atau null bila
/// [url] bukan URL Cloudinary — pemanggil merender apa adanya.
String? cloudinaryThumbnailUrl(
  String url, {
  int width = 200,
  int height = 200,
}) {
  final match = RegExp(
    r'^(https?://res\.cloudinary\.com/[^/]+/image/upload)/',
  ).firstMatch(url);
  if (match == null) return null;
  final rest = url.substring(match.end);
  return '${match.group(1)}/c_fill,w_$width,h_$height/$rest';
}

/// Widget bersama foto analisis (kolom `analyses.image_path`, Plan 3):
/// support **URL Cloudinary** (hasil upload) dan **path lokal** (capture
/// sebelum upload / data lama).
///
/// [thumbnail] true → URL Cloudinary di-resize lewat transformasi
/// `c_fill` (untuk kartu list, bukan full-size); path lokal tampil apa
/// adanya. Path kosong atau gambar gagal dimuat → placeholder ikon kopi
/// (tanpa crash, AC-4 Plan 3).
///
/// Ukuran ditentukan parent — gunakan di kartu dengan ukuran tetap.
class AnalysisImage extends StatelessWidget {
  const AnalysisImage({
    super.key,
    required this.imagePath,
    this.thumbnail = false,
  });

  /// URL Cloudinary atau path lokal; null/kosong → placeholder.
  final String? imagePath;

  /// true → thumbnail kecil (transformasi resize untuk URL Cloudinary).
  final bool thumbnail;

  @override
  Widget build(BuildContext context) {
    final path = imagePath?.trim();
    if (path == null || path.isEmpty) return const _ImagePlaceholder();

    if (path.startsWith('http://') || path.startsWith('https://')) {
      final url = thumbnail ? (cloudinaryThumbnailUrl(path) ?? path) : path;
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _ImagePlaceholder(),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _ImagePlaceholder(),
    );
  }
}

/// Placeholder: `surfaceContainer` + ikon kopi (token konsisten tema).
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RoastmateColors.surfaceContainer,
      child: const Center(
        child: Icon(Icons.coffee_outlined, color: RoastmateColors.iconMuted),
      ),
    );
  }
}
