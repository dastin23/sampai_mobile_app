import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../onboarding/widgets/form_widgets.dart';
import '../auth_scaffold.dart';
import '../providers/auth_providers.dart';

/// Masuk (PRD 4.2). Memanggil [AuthRepository], menampilkan error, lalu
/// menuju `/home` (redirect router yang akan mengarahkan sesuai onboarding).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  static final RegExp _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool _obscure = true;
  bool _loading = false;
  String? _emailError;
  String? _passwordError;
  String? _serverError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _email.text.trim();
    final password = _password.text;
    setState(() {
      _emailError = email.isEmpty
          ? 'Masukkan email.'
          : (_emailRegExp.hasMatch(email)
                ? null
                : 'Masukkan email yang valid.');
      _passwordError = password.isEmpty ? 'Masukkan kata sandi.' : null;
      _serverError = null;
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() {
      _loading = true;
      _serverError = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .signIn(email: _email.text, password: _password.text);
    if (!mounted) return;
    if (result.isSuccess) {
      context.go('/home');
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
      heading: 'Masuk',
      helper: 'Masuk untuk menyimpan pengaturanmu di akun SAMPAI.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Kata sandi',
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
          if (_serverError != null) ...[
            const SizedBox(height: AppSpacing.section),
            AuthErrorBanner(message: _serverError!),
          ],
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryCta(
            label: 'Masuk',
            loading: _loading,
            loadingLabel: 'Memasukkan…',
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.componentWide),
          TextButton(
            onPressed: _loading ? null : () => context.go('/register'),
            child: const Text('Belum punya akun? Daftar'),
          ),
        ],
      ),
    );
  }
}