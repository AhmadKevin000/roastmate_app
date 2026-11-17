import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_service.dart';

/// State sesi user (D-29).
class AuthState {
  const AuthState({this.userId, this.email, this.unavailable = false});

  /// null = belum login.
  final String? userId;
  final String? email;

  /// true = Supabase tidak dikonfigurasi (`.env` kosong) — fitur akun
  /// ditampilkan sebagai nonaktif.
  final bool unavailable;

  bool get loggedIn => userId != null;
}

/// Controller sesi auth. Membaca session awal Supabase lalu mendengarkan
/// perubahan (login/logout).
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final service = ref.watch(supabaseServiceProvider);
    final client = service.client;
    if (client == null) {
      return const AuthState(unavailable: true);
    }

    // Dengarkan perubahan sesi (login, logout, refresh token).
    client.auth.onAuthStateChange.listen((data) {
      state = _stateFromSession(client);
    });

    return _stateFromSession(client);
  }

  AuthState _stateFromSession(SupabaseClient client) {
    final session = client.auth.currentSession;
    final user = session?.user;
    return AuthState(userId: user?.id, email: user?.email);
  }

  /// Login email + sandi. Melempar `AuthApiException` bila kredensial salah.
  Future<void> signIn(String email, String password) async {
    final client = _requireClient();
    await client.auth.signInWithPassword(email: email, password: password);
    state = _stateFromSession(client);
  }

  /// Daftar akun baru. Melempar `AuthApiException` bila email terpakai.
  Future<void> signUp(String email, String password) async {
    final client = _requireClient();
    await client.auth.signUp(email: email, password: password);
    // Session bisa langsung terbentuk (email confirmation off) atau belum.
    state = _stateFromSession(client);
  }

  Future<void> signOut() async {
    final client = _requireClient();
    await client.auth.signOut();
    state = const AuthState();
  }

  SupabaseClient _requireClient() {
    final client = ref.read(supabaseServiceProvider).client;
    if (client == null) {
      throw StateError('Supabase tidak terkonfigurasi (.env).');
    }
    return client;
  }
}

/// Provider global sesi auth.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
