/// Register screen (FR-003) — collects full name, username, email,
/// password, and confirmation. Role is forced to `user` server-side via
/// the `handle_new_auth_user` trigger.
///
/// On success the router redirects to `/dashboard` (Supabase signs the
/// new user in immediately when email confirmation is disabled, which
/// is the default in our project setup).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/validators.dart';
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
      // Router redirect handles navigation to /dashboard.
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: loading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Buat akun pengguna baru',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Akun pengguna hanya dapat membuat dan melacak tiket sendiri.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Nama lengkap',
                      controller: _fullNameCtrl,
                      prefixIcon: Icons.badge_outlined,
                      textInputAction: TextInputAction.next,
                      validator: Validators.fullName,
                      enabled: !loading,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Username',
                      controller: _usernameCtrl,
                      prefixIcon: Icons.alternate_email,
                      textInputAction: TextInputAction.next,
                      validator: Validators.username,
                      enabled: !loading,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Email',
                      controller: _emailCtrl,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                      enabled: !loading,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Kata sandi',
                      controller: _passwordCtrl,
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: Validators.password,
                      enabled: !loading,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Konfirmasi kata sandi',
                      controller: _confirmCtrl,
                      prefixIcon: Icons.lock_person_outlined,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: Validators.confirmPassword(_passwordCtrl.text),
                      onSubmitted: (_) => _submit(),
                      enabled: !loading,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Daftar',
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
