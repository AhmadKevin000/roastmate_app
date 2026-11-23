import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/auth/auth_controller.dart';
import '../../../../../core/theme/roastmate_colors.dart';
import '../../../../../core/widgets/roastmate_app_header.dart';
import '../../../sync/data/sync_coordinator.dart';

/// Layar login (FR-10). Email + sandi via Supabase Auth.
///
/// Login tidak menggate fitur inti — hanya membuka sync riwayat (D-29).
/// Sync pertama dijalankan best-effort tepat setelah login sukses.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      await _syncBestEffort();
      if (!mounted) return;
      // Masuk ke Beranda (di dalam MainShell), bukan Profil: Profil berada di
      // luar ShellRoute dan tidak punya tombol kembali saat stack kosong.
      context.go('/home');
    } on AuthRetryableFetchException {
      // Gagal menjangkau server (DNS/offline/timeout) — bukan salah kredensial.
      setState(
        () => _errorMessage =
            'Tidak dapat menghubungi server. Periksa koneksi internet.',
      );
    } on AuthException catch (e) {
      // Mencakup AuthApiException (mis. email/sandi salah) sekaligus
      // AuthRetryableFetchException di atas — pesan asli server ditampilkan.
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Login gagal: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Sync pertama setelah login — best-effort: gagal tidak memblokir.
  Future<void> _syncBestEffort() =>
      ref.read(syncCoordinatorProvider).syncNow(force: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoastmateColors.background,
      appBar: const RoastmateAppHeader(subtitle: 'Masuk'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Masuk agar riwayat analisis tetap ada saat '
                'berganti perangkat.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Email wajib diisi';
                  if (!value.contains('@')) return 'Email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Kata sandi',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final value = v ?? '';
                  if (value.isEmpty) return 'Kata sandi wajib diisi';
                  if (value.length < 6) {
                    return 'Kata sandi minimal 6 karakter';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: RoastmateColors.statusError),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: RoastmateColors.primary,
                  foregroundColor: RoastmateColors.surface,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Masuk'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/register'),
                child: const Text('Belum punya akun? Daftar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
