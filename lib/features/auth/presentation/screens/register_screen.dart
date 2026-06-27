/// Register screen (FR-003) — collects full name, username, email,
/// password, and confirmation. Role is forced to `user` server-side via
/// the `handle_new_auth_user` trigger.
///
/// Minimal-clean layout matching the login screen: brand mark, editorial
/// heading, eyebrow field labels, generous whitespace. On success the
/// router redirects to `/dashboard`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final bool ok = await ref.read(authControllerProvider.notifier).register(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          username: _usernameCtrl.text,
          fullName: _fullNameCtrl.text,
        );
    if (!mounted) return;
    if (ok) {
      ref.read(authControllerProvider.notifier).clear();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Akun berhasil dibuat. Selamat datang!')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<String?>>(authControllerProvider, (_, next) {
      if (next is AsyncError) {
        final Object err = next.error!;
        final String msg = err is Failure ? err.message : err.toString();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      }
    });

    final bool loading = ref.watch(authControllerProvider).isLoading;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: loading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const BrandMark(size: 38),
                    const SizedBox(height: 24),
                    Text(
                      'Buat akun.',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Akun pengguna dapat membuat dan melacak tiket sendiri.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 28),

                    _FieldLabel(text: 'Nama lengkap'),
                    const SizedBox(height: 7),
                    CustomTextField(
                      label: 'Nama Anda',
                      controller: _fullNameCtrl,
                      prefixIcon: Icons.badge_outlined,
                      textInputAction: TextInputAction.next,
                      validator: Validators.fullName,
                      enabled: !loading,
                    ),
                    const SizedBox(height: 16),

                    _FieldLabel(text: 'Username'),
                    const SizedBox(height: 7),
                    CustomTextField(
                      label: 'username',
                      controller: _usernameCtrl,
                      prefixIcon: Icons.alternate_email,
                      textInputAction: TextInputAction.next,
                      validator: Validators.username,
                      enabled: !loading,
                    ),
                    const SizedBox(height: 16),

                    _FieldLabel(text: 'Email'),
                    const SizedBox(height: 7),
                    CustomTextField(
                      label: 'nama@email.com',
                      controller: _emailCtrl,
                      prefixIcon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                      enabled: !loading,
                    ),
                    const SizedBox(height: 16),

                    _FieldLabel(text: 'Kata sandi'),
                    const SizedBox(height: 7),
                    CustomTextField(
                      label: '••••••••',
                      controller: _passwordCtrl,
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: Validators.password,
                      enabled: !loading,
                    ),
                    const SizedBox(height: 16),

                    _FieldLabel(text: 'Konfirmasi kata sandi'),
                    const SizedBox(height: 7),
                    CustomTextField(
                      label: '••••••••',
                      controller: _confirmCtrl,
                      prefixIcon: Icons.lock_person_outlined,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: Validators.confirmPassword(_passwordCtrl.text),
                      onSubmitted: (_) => _submit(),
                      enabled: !loading,
                    ),
                    const SizedBox(height: 26),
                    PrimaryButton(
                      label: 'Daftar',
                      onPressed: loading ? null : _submit,
                      isLoading: loading,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Sudah punya akun?',
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: loading ? null : () => context.pop(),
                          child: const Text('Masuk'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.eyebrow.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}
