/// Login screen (FR-001) — email + password sign-in.
///
/// Minimal-clean layout: a small geometric brand mark, a left-aligned
/// editorial heading, generous whitespace, and a solid ink CTA. On
/// success the router's `refreshListenable` redirects to `/dashboard`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final bool ok = await ref.read(authControllerProvider.notifier).login(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
    if (!mounted) return;
    if (ok) {
      ref.read(authControllerProvider.notifier).clear();
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Brand mark + wordmark, left aligned.
                    Row(
                      children: <Widget>[
                        const BrandMark(size: 38),
                        const SizedBox(width: 11),
                        Text(
                          'Helpdesk',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 44),

                    // Editorial heading.
                    Text(
                      'Masuk.',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kelola dan lacak tiket dukungan Anda di satu tempat.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 36),

                    _FieldLabel(text: 'Email'),
                    const SizedBox(height: 7),
                    CustomTextField(
                      label: 'nama@email.com',
                      controller: _emailCtrl,
                      prefixIcon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                      enabled: !loading,
                    ),
                    const SizedBox(height: 18),

                    _FieldLabel(text: 'Kata sandi'),
                    const SizedBox(height: 7),
                    CustomTextField(
                      label: '••••••••',
                      controller: _passwordCtrl,
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: Validators.password,
                      onSubmitted: (_) => _submit(),
                      enabled: !loading,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: loading
                            ? null
                            : () => context.push(AppRoutes.resetPassword),
                        child: const Text('Lupa kata sandi?'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    PrimaryButton(
                      label: 'Masuk',
                      onPressed: loading ? null : _submit,
                      isLoading: loading,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Belum punya akun?',
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: loading
                              ? null
                              : () => context.push(AppRoutes.register),
                          child: const Text('Daftar'),
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

/// Small uppercase field label set in the mono "eyebrow" style.
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
