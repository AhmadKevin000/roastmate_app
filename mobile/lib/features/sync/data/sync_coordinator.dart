import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/cloudinary_service.dart';
import '../../../core/network/supabase_service.dart';
import '../../home/presentation/viewmodels/home_view_model.dart';
import 'sync_service.dart';

/// Berapa kali siklus sync berhasil — dipakai UI untuk menyegarkan daftar.
final syncTickProvider = NotifierProvider<SyncTickNotifier, int>(
  SyncTickNotifier.new,
);

class SyncTickNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// Satu pintu sync untuk seluruh aplikasi (login, Profil, lifecycle).
///
/// - single-flight: pemanggilan bersamaan memakai Future yang sama;
/// - throttled: maksimal sekali per 5 menit kecuali [force];
/// - best-effort: gagal jaringan tidak pernah melempar ke UI;
/// - dijadwalkan: [scheduleSync] menggabungkan beberapa perubahan lokal menjadi
///   satu siklus.
final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  return SyncCoordinator(ref);
});

class SyncCoordinator {
  SyncCoordinator(this._ref) {
    _ref.onDispose(() => _debounce?.cancel());
  }

  final Ref _ref;

  static const _throttle = Duration(minutes: 5);

  Future<SyncResult?>? _inFlight;
  DateTime? _lastRun;
  Timer? _debounce;

  /// Jadwalkan sync setelah penulisan lokal (scan, rating, resep, hapus).
  ///
  /// Debounce menggabungkan pemicu yang berdekatan. Memakai `force: true`
  /// supaya throttle pasif (5 menit saat app resume) tidak menunda data baru.
  void scheduleSync({Duration delay = const Duration(seconds: 2)}) {
    _debounce?.cancel();
    _debounce = Timer(delay, () {
      syncNow(force: true);
    });
  }

  Future<SyncResult?> syncNow({bool force = false}) {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final last = _lastRun;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < _throttle) {
      return Future.value(null);
    }

    final future = _run();
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  Future<SyncResult?> _run() async {
    try {
      final auth = _ref.read(authControllerProvider);
      final client = _ref.read(supabaseServiceProvider).client;
      if (client == null || auth.userId == null) return null;

      CloudinaryService? cloudinary;
      try {
        cloudinary = _ref.read(cloudinaryServiceProvider);
      } catch (_) {
        // Upload foto opsional — sync data tetap jalan.
      }

      final db = await AppDatabase.instance.database;
      final result = await SyncService(
        db,
        client,
        auth.userId!,
        cloudinary: cloudinary,
      ).run();

      _lastRun = DateTime.now();
      // Ringkasan Beranda bisa berubah (pull rating/resep dari device lain).
      _ref.invalidate(homeViewModelProvider);
      _ref.read(syncTickProvider.notifier).bump();
      return result;
    } catch (e) {
      debugPrint('[Sync] siklus gagal (best-effort): $e');
      return null;
    }
  }
}
