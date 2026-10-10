import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../onboarding/widgets/form_widgets.dart';
import '../auth_scaffold.dart';
import '../providers/auth_providers.dart';

/// Minta link reset kata sandi ke email (roadmap auth: lupa kata sandi).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _email = TextEditingController();

  static final RegExp _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool _loading = false;
  bool _sent = false;
  String? _emailError;
  String? _serverError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _validate(String value) {
    final email = value.trim();
    setState(() {
      _emailError = email.isEmpty
          ? 'Masukkan email.'
          : (_emailRegExp.hasMatch(email) ? null : 'Masukkan email yang valid.');
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_emailError != null || _email.text.trim().isEmpty) {
      _validate(_email.text);
      return;
    }
    setState(() {
      _loading = true;
      _serverError = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .resetPassword(email: _email.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _sent = true;
      } else {
        _serverError = result.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      onBack: () => context.go('/login'),
      heading: 'Lupa kata sandi',
      helper: 'Masukkan email terdaftar. Kami kirimkan link untuk '
          'mengatur ulang kata sandimu.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _email,
            enabled: !_loading && !_sent,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'nama@email.com',
              errorText: _emailError,
            ),
            onChanged: (_) {
              if (_emailError != null || _serverError != null) {
                _validate(_email.text);
              }
            },
          ),
          if (_serverError != null) ...[
            const SizedBox(height: AppSpacing.section),
            AuthErrorBanner(message: _serverError!),
          ],
          if (_sent) ...[
            const SizedBox(height: AppSpacing.section),
            AuthInfoBanner(
              message:
                  'Link reset telah dikirim ke ${_email.text.trim()}. '
                  'Periksa kotak masukmu ya.',
            ),
          ],
        ],
      ),
      footer: _sent
          ? PrimaryCta(
              label: 'Kembali ke Masuk',
              onPressed: () => context.go('/login'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryCta(
                  label: 'Kirim link reset',
                  loading: _loading,
                  loadingLabel: 'Mengirim…',
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.componentWide),
                TextButton(
                  onPressed: _loading ? null : () => context.go('/login'),
                  child: const Text('Ingat kata sandi? Masuk'),
                ),
              ],
            ),
    );
  }
}