import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';

/// Status hasil operasi sign in / sign up.
enum AuthStatus { success, requiresConfirmation, failure }

/// Hasil operasi autentikasi. [error] terisi hanya saat [failure].
@immutable
class AuthOutcome {
  const AuthOutcome.success() : status = AuthStatus.success, error = null;

  const AuthOutcome.requiresConfirmation()
    : status = AuthStatus.requiresConfirmation,
      error = null;

  const AuthOutcome.failure(this.error) : status = AuthStatus.failure;

  final AuthStatus status;
  final String? error;

  bool get isSuccess => status == AuthStatus.success;
}

/// Kontrak repository autentikasi agar UI dan router dapat diuji tanpa
/// backend nyata.
abstract interface class AuthRepository {
  Session? get currentSession;

  bool get isAuthenticated;

  Stream<AuthState> get authStateChanges;

  Future<AuthOutcome> signIn({required String email, required String password});

  Future<AuthOutcome> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  /// Kirim email reset kata sandi lewat Supabase Auth.
  Future<AuthOutcome> resetPassword({required String email});

  /// Terapkan kata sandi baru (dipakai saat sesi recovery/reset).
  Future<AuthOutcome> updatePassword({required String password});

  Future<void> signOut();
}

/// Implementasi Supabase Auth (PRD 4.2).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({SupabaseClient? client})
    : _client = client ?? supabase;

  final SupabaseClient _client;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  bool get isAuthenticated => _client.auth.currentSession != null;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return const AuthOutcome.success();
    } on AuthException catch (e) {
      return AuthOutcome.failure(
        friendlyAuthError(e, fallback: 'Email atau kata sandi salah.'),
      );
    } catch (_) {
      return const AuthOutcome.failure('Belum berhasil masuk. Coba lagi.');
    }
  }

  @override
  Future<AuthOutcome> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      if (fullName.trim().length < 2) {
        return const AuthOutcome.failure('Nama lengkap minimal 2 karakter.');
      }

      final result = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );

      if (result.session == null) {
        return const AuthOutcome.requiresConfirmation();
      }

      return const AuthOutcome.success();
    } on AuthException catch (e) {
      return AuthOutcome.failure(
        friendlyAuthError(e, fallback: 'Belum berhasil mendaftar. Coba lagi.'),
      );
    } catch (_) {
      return const AuthOutcome.failure('Belum berhasil mendaftar. Coba lagi.');
    }
  }

  @override
  Future<AuthOutcome> resetPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: _resetRedirectTo(),
      );
      return const AuthOutcome.success();
    } on AuthException catch (e) {
      return AuthOutcome.failure(
        friendlyAuthError(e, fallback: 'Belum berhasil mengirim link. Coba lagi.'),
      );
    } catch (_) {
      return const AuthOutcome.failure('Belum berhasil mengirim link. Coba lagi.');
    }
  }

  /// Redirect URL ke aplikasi hanya di Android (konfigurasi deep link
  /// `sampai://` dipasang di AndroidManifest). Platform lain memakai alur
  /// default (Site URL dashboard) agar web/desktop tidak rusak.
  String? _resetRedirectTo() =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? sampaiAuthRedirectUrl
      : null;

  @override
  Future<AuthOutcome> updatePassword({required String password}) async {
    try {
      if (password.length < 6) {
        return const AuthOutcome.failure('Kata sandi minimal 6 karakter.');
      }
      await _client.auth.updateUser(UserAttributes(password: password));
      return const AuthOutcome.success();
    } on AuthException catch (e) {
      return AuthOutcome.failure(
        friendlyAuthError(e, fallback: 'Belum berhasil menyimpan. Coba lagi.'),
      );
    } catch (_) {
      return const AuthOutcome.failure('Belum berhasil menyimpan. Coba lagi.');
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

/// Terjemahkan pesan error backend ke Bahasa Indonesia yang ramah.
String friendlyAuthError(Object error, {required String fallback}) {
  if (error is AuthException) {
    final m = error.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Email atau kata sandi salah.';
    }
    if (m.contains('user already registered')) {
      return 'Email sudah terdaftar.';
    }
    if (m.contains('password should be at least 6 characters')) {
      return 'Kata sandi minimal 6 karakter.';
    }
    if (m.contains('rate limit')) {
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    }
  }
  return fallback;
}
