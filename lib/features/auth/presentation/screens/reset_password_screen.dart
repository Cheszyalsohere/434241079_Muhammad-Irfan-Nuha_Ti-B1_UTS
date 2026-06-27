/// Reset password screen (FR-004) — collects an email address and asks
/// Supabase to send a password-reset link. After a successful request
/// the screen swaps to a confirmation panel.
///
/// Minimal-clean styling consistent with login/register.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final bool ok = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(email: _emailCtrl.text);
    if (!mounted) return;
    if (ok) {
      ref.read(authControllerProvider.notifier).clear();
      setState(() => _sent = true);
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _sent
                  ? _SentPanel(
                      email: _emailCtrl.text.trim(),
                      onBackToLogin: () => context.pop(),
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _IconTile(icon: Icons.lock_reset_outlined),
                          const SizedBox(height: 22),
                          Text(
                            'Lupa kata sandi?',
                            style: AppTextStyles.displayLarge.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Masukkan email akun Anda. Kami akan mengirim '
                            'tautan untuk mengatur ulang kata sandi.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 28),
                          _FieldLabel(text: 'Email'),
                          const SizedBox(height: 7),
                          CustomTextField(
                            label: 'nama@email.com',
                            controller: _emailCtrl,
                            prefixIcon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            validator: Validators.email,
                            onSubmitted: (_) => _submit(),
                            enabled: !loading,
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'Kirim Tautan Reset',
                            onPressed: loading ? null : _submit,
                            isLoading: loading,
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

/// A small square tile holding an icon — echoes the brand-mark shape.
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: scheme.primary, size: 24),
    );
  }
}

class _SentPanel extends StatelessWidget {
  const _SentPanel({required this.email, required this.onBackToLogin});

  final String email;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColorsTint.success(context),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            color: theme.colorScheme.tertiary,
            size: 24,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Tautan terkirim.',
          style: AppTextStyles.displayLarge.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Jika $email terdaftar, Anda akan menerima email berisi tautan '
          'untuk mengatur ulang kata sandi. Periksa folder spam jika tidak '
          'muncul dalam beberapa menit.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 26),
        PrimaryButton(label: 'Kembali ke Login', onPressed: onBackToLogin),
      ],
    );
  }
}

/// Tint helper kept local to avoid leaking a one-off colour into the
/// global palette.
abstract final class AppColorsTint {
  static Color success(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.12);
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
