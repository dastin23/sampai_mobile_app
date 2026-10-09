import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../onboarding/widgets/form_widgets.dart';
import '../auth_scaffold.dart';
import '../data/auth_repository.dart';
import '../providers/auth_providers.dart';

/// Daftar akun baru (PRD 4.2). Memanggil [AuthRepository] lalu menuju `/home`
/// (redirect router menyesuaikan status onboarding). Bila verifikasi email
/// aktif, tampilkan pesan informasi.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  static final RegExp _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool _obscure = true;
  bool _loading = false;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _serverError;
  String? _infoMessage;
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _validate() {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final confirm = _confirm.text;
    setState(() {
      _nameError = name.isEmpty
          ? 'Masukkan nama lengkap.'
          : (name.length < 2 ? 'Nama minimal 2 karakter.' : null);
      _emailError = email.isEmpty
          ? 'Masukkan email.'
          : (_emailRegExp.hasMatch(email)
                ? null
                : 'Masukkan email yang valid.');
      _passwordError = password.isEmpty
          ? 'Buat kata sandi.'
          : (password.length < 6 ? 'Kata sandi minimal 6 karakter.' : null);
      _confirmError = confirm.isEmpty
          ? 'Ulangi kata sandi.'
          : (confirm != password ? 'Kata sandi tidak sama.' : null);
      _serverError = null;
    });
    return name.length >= 2 &&
        _emailError == null &&
        _passwordError == null &&
        _confirmError == null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() {
      _loading = true;
      _infoMessage = null;
    });

    final result = await ref
        .read(authRepositoryProvider)
        .signUp(
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    if (result.isSuccess) {
      context.go('/home');
      return;
    }
    if (result.status == AuthStatus.requiresConfirmation) {
      setState(() {
        _loading = false;
        _infoMessage = 'Akun dibuat. Silakan verifikasi email untuk masuk.';
      });
      return;
    }
    setState(() {
      _loading = false;
      _serverError = result.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      onBack: () => context.go('/login'),
      heading: 'Daftar',
      helper:
          'Buat akun gratis. Data rencanamu tersimpan secara terpisah '
          'per akun.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            enabled: !_loading,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: InputDecoration(
              labelText: 'Nama lengkap',
              hintText: 'Masukkan nama lengkap',
              errorText: _nameError,
            ),
            onChanged: (_) {
              if (_nameError != null || _serverError != null) {
                setState(() {
                  _nameError = null;
                  _serverError = null;
                });
              }
            },
          ),
          const SizedBox(height: AppSpacing.componentWide),
          TextField(
            controller: _email,
            enabled: !_loading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'nama@email.com',
              errorText: _emailError,
            ),
            onChanged: (_) {
              if (_emailError != null || _serverError != null) {
                setState(() {
                  _emailError = null;
                  _serverError = null;
                });
              }
            },
          ),
          const SizedBox(height: AppSpacing.componentWide),
          TextField(
            controller: _password,
            enabled: !_loading,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Kata sandi',
              hintText: 'Minimal 6 karakter',
              errorText: _passwordError,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                tooltip: _obscure
                    ? 'Tampilkan kata sandi'
                    : 'Sembunyikan kata sandi',
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            onChanged: (_) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
            },
          ),
          const SizedBox(height: AppSpacing.componentWide),
          TextField(
            controller: _confirm,
            enabled: !_loading,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Ulangi kata sandi',
              errorText: _confirmError,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                tooltip: _obscure
                    ? 'Tampilkan kata sandi'
                    : 'Sembunyikan kata sandi',
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            onChanged: (_) {
              if (_confirmError != null) {
                setState(() => _confirmError = null);
              }
            },
          ),
          if (_serverError != null) ...[
            const SizedBox(height: AppSpacing.section),
            AuthErrorBanner(message: _serverError!),
          ],
          if (_infoMessage != null) ...[
            const SizedBox(height: AppSpacing.section),
            AuthInfoBanner(message: _infoMessage!),
          ],
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryCta(
            label: 'Daftar',
            loading: _loading,
            loadingLabel: 'Mendaftarkan…',
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.componentWide),
          TextButton(
            onPressed: _loading ? null : () => context.go('/login'),
            child: const Text('Sudah punya akun? Masuk'),
          ),
        ],
      ),
    );
  }
}
