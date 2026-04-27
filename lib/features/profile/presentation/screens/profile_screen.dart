/// Profile screen (Phase 7 — polish).
///
/// Sections (top → bottom):
///   • Header card: avatar (with camera-icon overlay button) + display
///     name + @username + role chip
///   • Edit-mode form (full name, username) — toggled by the AppBar
///     edit / save / cancel actions
///   • Info ListTile rows: full name, username, role, email
///   • Theme toggle
///   • "Ganti Password" tile → /profile/change-password
///   • Logout tile (red) with confirmation dialog
///
/// Avatar flow: tap the camera button → pick source → image_picker →
/// image_cropper (1:1) → upload to Supabase Storage at
/// `avatars/<uid>.jpg` → update profile row → refresh both
/// [profileControllerProvider] and the auth stream-backed
/// [currentUserProvider] (the latter is what every other screen
/// already watches for the avatar).
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeletons/profile_skeleton.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/avatar_picker_bottom_sheet.dart';
import '../widgets/theme_toggle.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _usernameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController();
    _usernameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  /// Sync the controllers with the latest entity. Called every build
  /// while *not* editing — once the user enters edit mode we leave the
  /// fields alone so their typing isn't clobbered.
  void _syncControllers(UserEntity user) {
    if (_fullNameCtrl.text != user.fullName) {
      _fullNameCtrl.text = user.fullName;
    }
    if (_usernameCtrl.text != user.username) {
      _usernameCtrl.text = user.username;
    }
  }

  Future<void> _showSnack(String msg) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onSave(UserEntity user) async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final bool ok = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          fullName: _fullNameCtrl.text,
          username: _usernameCtrl.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ref.read(isEditingProfileProvider.notifier).exit();
      await _showSnack('Profil berhasil diperbarui');
    } else {
      final Object? err = ref.read(profileControllerProvider).error;
      final String msg = err is Failure ? err.message : 'Gagal menyimpan.';
      await _showSnack(msg);
    }
  }

  void _onCancel(UserEntity user) {
    _fullNameCtrl.text = user.fullName;
    _usernameCtrl.text = user.username;
    ref.read(isEditingProfileProvider.notifier).exit();
  }

  // ── Avatar flow ─────────────────────────────────────────────────────

  Future<void> _onAvatarTap(UserEntity user) async {
    final AvatarPickerAction? action = await showAvatarPickerBottomSheet(
      context,
      hasAvatar: user.avatarUrl != null && user.avatarUrl!.isNotEmpty,
    );
    if (action == null || !mounted) return;

    if (action == AvatarPickerAction.remove) {
      ref.read(isUploadingAvatarProvider.notifier).set(true);
      final bool ok = await ref
          .read(profileControllerProvider.notifier)
          .clearAvatar();
      if (!mounted) return;
      ref.read(isUploadingAvatarProvider.notifier).set(false);
      if (ok) {
        await _showSnack('Foto profil dihapus');
      } else {
        final Object? err = ref.read(profileControllerProvider).error;
        final String msg = err is Failure
            ? err.message
            : 'Gagal menghapus foto.';
        await _showSnack(msg);
      }
      return;
    }

    final ImageSource source = action == AvatarPickerAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;

    if (source == ImageSource.camera) {
      final PermissionStatus status = await Permission.camera.request();
      if (!mounted) return;
      if (!status.isGranted) {
        await _showSnack('Izin kamera diperlukan untuk mengambil foto.');
        return;
      }
    }

    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      uiSettings: <PlatformUiSettings>[
        AndroidUiSettings(
          toolbarTitle: 'Crop Foto',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.primary,
          lockAspectRatio: true,
          hideBottomControls: false,
          initAspectRatio: CropAspectRatioPreset.square,
        ),
        IOSUiSettings(
          title: 'Crop Foto',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    if (cropped == null || !mounted) return;

    final File file = File(cropped.path);
    final Uint8List bytes = await file.readAsBytes();
    if (!mounted) return;

    ref.read(isUploadingAvatarProvider.notifier).set(true);
    final bool ok =
        await ref.read(profileControllerProvider.notifier).uploadAvatar(
              bytes: bytes,
              extension: 'jpg',
            );
    if (!mounted) return;
    ref.read(isUploadingAvatarProvider.notifier).set(false);

    if (ok) {
      await _showSnack('Foto profil diperbarui');
    } else {
      final Object? err = ref.read(profileControllerProvider).error;
      final String msg = err is Failure
          ? err.message
          : 'Gagal mengunggah foto.';
      await _showSnack(msg);
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────

  Future<void> _confirmAndLogout() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Kamu akan keluar dari sesi ini.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) {
      ref.read(authControllerProvider.notifier).clear();
    }
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Toast on auth-controller errors (e.g. logout failure).
    ref.listen<AsyncValue<String?>>(authControllerProvider, (_, next) {
      if (next is AsyncError) {
        final Object err = next.error!;
        final String msg = err is Failure ? err.message : err.toString();
        _showSnack(msg);
      }
    });

    final AsyncValue<UserEntity?> async = ref.watch(profileControllerProvider);
    final bool isEditing = ref.watch(isEditingProfileProvider);
    final bool isUploading = ref.watch(isUploadingAvatarProvider);
    final bool loggingOut = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: <Widget>[
          if (async.valueOrNull != null)
            if (isEditing) ...<Widget>[
              IconButton(
                tooltip: 'Batal',
                icon: const Icon(Icons.close),
                onPressed: _saving ? null : () => _onCancel(async.value!),
              ),
              IconButton(
                tooltip: 'Simpan',
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Icon(Icons.check),
                onPressed: _saving ? null : () => _onSave(async.value!),
              ),
            ] else
              IconButton(
                tooltip: 'Edit Profil',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    ref.read(isEditingProfileProvider.notifier).enter(),
              ),
        ],
      ),
      body: async.when(
        loading: () => const ProfileSkeleton(),
        error: (Object err, _) => ErrorState(
          message: 'Gagal memuat profil.',
          details: err is Failure ? err.message : err.toString(),
          onRetry: () => ref.invalidate(profileControllerProvider),
        ),
        data: (UserEntity? user) {
          if (user == null) return const _SignedOut();
          if (!isEditing) _syncControllers(user);
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(profileControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                _Header(
                  user: user,
                  isUploading: isUploading,
                  onAvatarTap: () => _onAvatarTap(user),
                ),
                const SizedBox(height: 16),
                if (isEditing)
                  _EditForm(
                    formKey: _formKey,
                    fullNameCtrl: _fullNameCtrl,
                    usernameCtrl: _usernameCtrl,
                  )
                else
                  _InfoCard(user: user),
                const SizedBox(height: 24),
                const _SectionHeader('Tampilan'),
                const SizedBox(height: 8),
                const ThemeToggle(),
                const SizedBox(height: 24),
                const _SectionHeader('Keamanan'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_reset_outlined),
                    title: const Text('Ganti Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.changePassword),
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionHeader('Akun'),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer
                      .withValues(alpha: 0.35),
                  child: ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      'Keluar',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: loggingOut
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                            ),
                          )
                        : Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.error,
                          ),
                    onTap: loggingOut ? null : _confirmAndLogout,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Header card ───────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.isUploading,
    required this.onAvatarTap,
  });

  final UserEntity user;
  final bool isUploading;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String roleLabel = AppLabels.role[user.role.wire] ?? user.role.wire;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                _Avatar(user: user, isUploading: isUploading),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Material(
                    color: scheme.primary,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: isUploading ? null : onAvatarTap,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.photo_camera_outlined,
                          size: 18,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              user.fullName,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              '@${user.username}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                roleLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.isUploading});

  final UserEntity user;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? url = user.avatarUrl;
    final bool hasUrl = url != null && url.isNotEmpty;

    final Widget circle = CircleAvatar(
      radius: 48,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: hasUrl
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: url,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (_, __, ___) => Text(
                  _initialsFor(user),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            )
          : Text(
              _initialsFor(user),
              style: Theme.of(context).textTheme.titleLarge,
            ),
    );

    if (!isUploading) return circle;
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        circle,
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _initialsFor(UserEntity u) {
    final List<String> parts = u.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

// ── Info / edit form ──────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final String roleLabel = AppLabels.role[user.role.wire] ?? user.role.wire;
    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Nama Lengkap'),
            subtitle: Text(user.fullName),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.alternate_email_outlined),
            title: const Text('Username'),
            subtitle: Text(user.username),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Peran'),
            subtitle: Text(roleLabel),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(user.email.isEmpty ? '—' : user.email),
          ),
        ],
      ),
    );
  }
}

class _EditForm extends StatelessWidget {
  const _EditForm({
    required this.formKey,
    required this.fullNameCtrl,
    required this.usernameCtrl,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameCtrl;
  final TextEditingController usernameCtrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: fullNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                textInputAction: TextInputAction.next,
                validator: (String? v) {
                  final String t = (v ?? '').trim();
                  if (t.isEmpty) return 'Nama lengkap wajib diisi.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.alternate_email_outlined),
                ),
                validator: (String? v) {
                  final String t = (v ?? '').trim();
                  if (t.isEmpty) return 'Username wajib diisi.';
                  if (t.contains(' ')) {
                    return 'Username tidak boleh mengandung spasi.';
                  }
                  if (t.length < 3) return 'Minimal 3 karakter.';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Misc ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Belum masuk.'),
      ),
    );
  }
}


