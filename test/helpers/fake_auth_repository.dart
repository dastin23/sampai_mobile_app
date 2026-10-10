import 'dart:async';

import 'package:sampai_app/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fake [AuthRepository] untuk test. Mengumpulkan panggilan masuk, daftar,
/// dan reset kata sandi, serta mengemisi event auth seperti implementasi
/// Supabase agar redirect router dapat diuji.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.authenticated = false});

  bool authenticated;
  AuthOutcome signInResult = const AuthOutcome.success();
  AuthOutcome signUpResult = const AuthOutcome.success();
  AuthOutcome resetPasswordResult = const AuthOutcome.success();
  AuthOutcome updatePasswordResult = const AuthOutcome.success();

  final List<(String, String)> logins = [];
  final List<(String, String, String)> registrations = [];
  final List<String> resetPasswords = [];
  final List<String> updatedPasswords = [];

  final StreamController<AuthState> _authController =
      StreamController<AuthState>.broadcast();

  @override
  Session? get currentSession => null;

  @override
  bool get isAuthenticated => authenticated;

  @override
  Stream<AuthState> get authStateChanges => _authController.stream;

  @override
  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) async {
    logins.add((email, password));
    if (signInResult.isSuccess) {
      authenticated = true;
      _authController.add(AuthState(AuthChangeEvent.signedIn, null));
    }
    return signInResult;
  }

  @override
  Future<AuthOutcome> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    registrations.add((fullName, email, password));
    if (signUpResult.isSuccess) {
      authenticated = true;
      _authController.add(AuthState(AuthChangeEvent.signedIn, null));
    }
    return signUpResult;
  }

  @override
  Future<AuthOutcome> resetPassword({required String email}) async {
    resetPasswords.add(email);
    return resetPasswordResult;
  }

  @override
  Future<AuthOutcome> updatePassword({required String password}) async {
    updatedPasswords.add(password);
    return updatePasswordResult;
  }

  /// Simulasikan link reset dibuka: sesi aktif + event `passwordRecovery`.
  void emitPasswordRecovery() {
    authenticated = true;
    _authController.add(AuthState(AuthChangeEvent.passwordRecovery, null));
  }

  @override
  Future<void> signOut() async {
    authenticated = false;
    _authController.add(AuthState(AuthChangeEvent.signedOut, null));
  }
}