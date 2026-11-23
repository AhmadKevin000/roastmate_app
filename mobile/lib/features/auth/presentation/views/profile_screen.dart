import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/auth/auth_controller.dart';
import '../../../../../core/theme/roastmate_colors.dart';
import '../../../../../core/widgets/roastmate_app_header.dart';
import '../../../sync/data/sync_coordinator.dart';

/// Layar profil (FR-10): status login, sinkronisasi manual, logout.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _syncing = false;
  String? _syncMessage;

  Future<void> _syncNow() async {
    setState(() {
      _syncing = true;
      _syncMessage = null;
    });
    try {
      final result = await ref
          .read(syncCoordinatorProvider)
          .syncNow(force: true);
      if (!mounted) return;
      setState(
        () => _syncMessage = result?.label ??
            'Tidak ada akun aktif atau Supabase belum dikonfigurasi.',
      );
    } catch (_) {
      if (mounted) {
        setState(() => _syncMessage = 'Sinkron gagal. Periksa koneksi internet.');
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: RoastmateColors.background,
      appBar: RoastmateAppHeader(
        subtitle: 'Akun',
        // Profil dibuka lewat ikon pengaturan (push) → tombol kembali normal.
        // Fallback ke Beranda bila stack kosong (mis. navigasi programatik).
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(
            Icons.arrow_back,
            color: RoastmateColors.primary,
          ),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (auth.unavailable)
            const _InfoCard(
              title: 'Fitur akun nonaktif',
              body:
                  'Kredensial Supabase belum dikonfigurasi di .env. '
                  'Aplikasi tetap berfungsi offline seperti biasa.',
            )
          else if (!auth.loggedIn) ...[
            const _InfoCard(
              title: 'Belum masuk',
              body:
                  'Masuk agar riwayat analisis tersimpan di cloud '
                  'dan bisa dibuka di perangkat lain.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/login'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: RoastmateColors.primary,
                foregroundColor: RoastmateColors.surface,
              ),
              child: const Text('Masuk'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text('Daftar akun baru'),
            ),
          ] else ...[
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: RoastmateColors.surfaceContainer,
                  child: Text(
                    (auth.email ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                      color: RoastmateColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(auth.email ?? '-'),
                subtitle: const Text('Riwayat tersinkron ke akun ini'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _syncing ? null : _syncNow,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: RoastmateColors.primary,
                foregroundColor: RoastmateColors.surface,
              ),
              icon: _syncing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: const Text('Sinkron sekarang'),
            ),
            if (_syncMessage != null) ...[
              const SizedBox(height: 12),
              Text(_syncMessage!),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: RoastmateColors.statusError,
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
