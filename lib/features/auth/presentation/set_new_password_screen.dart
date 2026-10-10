import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../onboarding/widgets/form_widgets.dart';
import '../auth_scaffold.dart';
import '../providers/auth_providers.dart';
import '../providers/password_reset_provider.dart';

/// Setel kata sandi baru setelah pengguna membuka link reset dari email
/// (`AuthChangeEvent.passwordRecovery`).
class SetNewPasswordScreen extends ConsumerStatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  ConsumerState<SetNewPasswordScreen> createState() =>
      _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends ConsumerState<SetNewPasswordScreen> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _passwordError;
  String? _confirmError;
  String? _serverError;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _validate() {
    final password = _password.text;
    final confirm = _confirm.text;
    setState(() {
      _passwordError = password.isEmpty
          ? 'Masukkan kata sandi baru.'
          : (password.length < 6 ? 'Kata sandi minimal 6 karakter.' : null);
      _confirmError = confirm.isEmpty
          ? 'Ulangi kata sandi baru.'
          : (confirm == password ? null : 'Kata sandi tidak sama.');
      _serverError = null;
    });
    return _passwordError == null && _confirmError == null;
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
        .updatePassword(password: _password.text);
    if (!mounted) return;
    if (result.isSuccess) {
      ref.read(pendingPasswordResetProvider.notifier).clear();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Kata sandi berhasil diperbarui.')),
        );
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
      heading: 'Kata sandi baru',
      helper: 'Buat kata sandi baru untuk akunmu. Minimal 6 karakter.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _password,
            enabled: !_loading,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Kata sandi baru',
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
              if (_passwordError != null || _serverError != null) {
                setState(() {
                  _passwordError = null;
                  _serverError = null;
                });
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
              labelText: 'Ulangi kata sandi baru',
              errorText: _confirmError,
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
        ],
      ),
      footer: PrimaryCta(
        label: 'Simpan kata sandi baru',
        loading: _loading,
        loadingLabel: 'Menyimpan…',
        onPressed: _submit,
      ),
    );
  }
}
