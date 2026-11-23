import 'dart:io';

import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Upload best-effort foto analisis ke Cloudinary (AC-02: alur inti tetap
/// jalan offline).
///
/// Kredensial dibaca dari file `.env` ter-bundle (`flutter_dotenv`):
/// `CLOUD_NAME`, `CLOUDINARY_API`, `CLOUDINARY_SECRET`. Catatan: signed upload
/// dari sisi klien berarti secret ikut ter-bundle di APK — diterima untuk
/// proyek lokal (keputusan `docs/plans` Plan 2); untuk rilis publik pindah ke
/// unsigned upload preset.
class CloudinaryService {
  CloudinaryService({Cloudinary? client}) : _client = client;

  final Cloudinary? _client;
  Cloudinary? _cachedClient;

  Cloudinary? get _activeClient {
    final injected = _client;
    if (injected != null) return injected;
    _cachedClient ??= _buildFromEnv();
    return _cachedClient;
  }

  Cloudinary? _buildFromEnv() {
    if (!dotenv.isInitialized) {
      debugPrint('[Cloudinary] dotenv belum di-load — upload dilewati.');
      return null;
    }
    final cloudName = dotenv.env['CLOUD_NAME'];
    final apiKey = dotenv.env['CLOUDINARY_API'];
    final apiSecret = dotenv.env['CLOUDINARY_SECRET'];
    if (cloudName == null ||
        apiKey == null ||
        apiSecret == null ||
        cloudName.isEmpty ||
        apiKey.isEmpty ||
        apiSecret.isEmpty) {
      debugPrint('[Cloudinary] kredensial .env tidak lengkap — upload dilewati.');
      return null;
    }
    return Cloudinary.signed(
      cloudName: cloudName,
      apiKey: apiKey,
      apiSecret: apiSecret,
    );
  }

  /// Upload [file] ke folder [folder] (incoming transform `q_auto`) →
  /// `secure_url` (mis. `https://res.cloudinary.com/<cloud>/...`).
  ///
  /// Return `null` bila client tak tersedia atau upload gagal — semua
  /// exception ditelan, caller tidak perlu try/catch (best-effort).
  Future<String?> uploadImage(
    File file, {
    String folder = 'roastmate/analyses',
  }) async {
    final client = _activeClient;
    if (client == null) return null;
    try {
      final result = await client.upload.upload(
        file: CloudinaryFileSource.path(file.path),
        resourceType: CloudinaryResourceType.image,
        folder: folder,
        transformation: 'q_auto',
      );
      final url = result.secureUrl;
      if (url == null || url.isEmpty) {
        debugPrint('[Cloudinary] upload sukses tetapi secure_url kosong.');
        return null;
      }
      return url;
    } catch (e) {
      debugPrint('[Cloudinary] upload gagal (best-effort, dilewati): $e');
      return null;
    }
  }
}

/// Instance layanan Cloudinary untuk injeksi dependensi alur scan.
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

/// Ambil `public_id` dari `secure_url` Cloudinary (audit & cleanup aset).
///
/// `.../upload/v1712/roastmate/analyses/abc.jpg` → `roastmate/analyses/abc`.
String? cloudinaryPublicIdFromUrl(String url) {
  final marker = '/upload/';
  final start = url.indexOf(marker);
  if (start < 0) return null;
  var rest = url.substring(start + marker.length);
  if (rest.startsWith('v')) {
    final slash = rest.indexOf('/');
    if (slash > 0 && int.tryParse(rest.substring(1, slash)) != null) {
      rest = rest.substring(slash + 1);
    }
  }
  final dot = rest.lastIndexOf('.');
  return dot > 0 ? rest.substring(0, dot) : rest;
}
