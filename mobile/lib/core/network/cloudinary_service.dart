import 'dart:io';

import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_env.dart';

/// Upload best-effort foto analisis ke Cloudinary (AC-02: alur inti tetap
/// jalan offline).
///
/// Kredensial dibaca dari [AppEnv] (dart-define saat build): `CLOUD_NAME` dan
/// `CLOUDINARY_UPLOAD_PRESET`. Upload memakai preset **unsigned** — tidak ada
/// API key/secret yang ikut ter-bundle di APK. Preset wajib dibuat dengan
/// signing mode "Unsigned" di Cloudinary → Upload Settings → Upload presets.
class CloudinaryService {
  CloudinaryService({Cloudinary? client, String? uploadPreset})
      : _client = client,
        _preset = uploadPreset ?? AppEnv.cloudinaryUploadPreset;

  final Cloudinary? _client;
  final String _preset;
  Cloudinary? _cachedClient;

  Cloudinary? get _activeClient {
    final injected = _client;
    if (injected != null) return injected;
    _cachedClient ??= _buildFromEnv();
    return _cachedClient;
  }

  Cloudinary? _buildFromEnv() {
    if (!AppEnv.hasCloudinary) {
      debugPrint('[Cloudinary] preset/cloud tidak dikonfigurasi — upload dilewati.');
      return null;
    }
    return Cloudinary.unsigned(cloudName: AppEnv.cloudName);
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
      final result = await client.upload.unsignedUpload(
        file: CloudinaryFileSource.path(file.path),
        uploadPreset: _preset,
        resourceType: CloudinaryResourceType.image,
        folder: folder,
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
