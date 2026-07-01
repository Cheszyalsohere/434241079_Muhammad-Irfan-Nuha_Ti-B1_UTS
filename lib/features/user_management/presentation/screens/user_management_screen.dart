/// Admin User Management screen (FR-007.7 + BR-002.9).
///
/// Lists every profile with name, @username, role, and active state.
/// Admins can change a user's role and activate / deactivate accounts
/// via a bottom sheet. The signed-in admin cannot change their own role
/// or deactivate themselves (guards against accidental lockout).
///
/// Access is admin-only: the route is only surfaced to admins, and this
/// screen renders a "no access" panel for anyone else who reaches it.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/user_management_provider.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState
    extends ConsumerState<UserManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(userSearchQueryProvider.notifier).set(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final UserEntity? me = ref.watch(currentUserProvider).valueOrNull;
    final bool isAdmin = me?.role.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pengguna'),
        actions: <Widget>[
          if (isAdmin)
            IconButton(
              tooltip: _searchOpen ? 'Tutup pencarian' : 'Cari',
              icon: Icon(_searchOpen ? Icons.close : Icons.search),
              onPressed: () {
                setState(() => _searchOpen = !_searchOpen);
                if (!_searchOpen) {
                  _searchCtrl.clear();
                  ref.read(userSearchQueryProvider.notifier).set('');
                }
              },
            ),
        ],
      ),
      body: !isAdmin
          ? const _NoAccess()
          : Column(
              children: <Widget>[
                if (_searchOpen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: ResponsiveCenter(
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Cari nama atau username...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          isDense: true,
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                Expanded(
                  child: ResponsiveCenter(
                    child: _UserList(currentUserId: me?.id),
                  ),
                ),
              ],
            ),
    );
  }
}

class _UserList extends ConsumerWidget {
  const _UserList({required this.currentUserId});

  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<UserEntity>> async =
        ref.watch(userManagementControllerProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object err, _) => ErrorState(
        message: 'Gagal memuat pengguna.',
        details: err.toString(),
        onRetry: () =>
            ref.read(userManagementControllerProvider.notifier).refresh(),
      ),
      data: (List<UserEntity> users) {
        if (users.isEmpty) {
          return const EmptyState(
            title: 'Tidak ada pengguna',
            subtitle: 'Belum ada akun yang cocok dengan pencarian.',
            icon: Icons.people_outline,
          );
        }
        // Summary counts header + list.
        final int admins = users.where((UserEntity u) => u.role.isAdmin).length;
        final int helpdesk =
            users.where((UserEntity u) => u.role.isHelpdesk).length;
        final int inactive =
            users.where((UserEntity u) => !u.isActive).length;

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(userManagementControllerProvider.notifier).refresh(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: users.length + 1,
            separatorBuilder: (_, int i) =>
                SizedBox(height: i == 0 ? 4 : 10),
            itemBuilder: (BuildContext context, int i) {
              if (i == 0) {
                return _CountsBar(
                  total: users.length,
                  admins: admins,
                  helpdesk: helpdesk,
                  inactive: inactive,
                );
              }
              final UserEntity u = users[i - 1];
              return _UserRow(
                key: ValueKey<String>(u.id),
                user: u,
                isSelf: u.id == currentUserId,
                onManage: () => _openManageSheet(context, ref, u),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openManageSheet(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
  ) async {
    final bool isSelf = user.id == currentUserId;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => _ManageSheet(user: user, isSelf: isSelf),
    );
  }
}

// ── Counts bar ────────────────────────────────────────────────────────

class _CountsBar extends StatelessWidget {
  const _CountsBar({
    required this.total,
    required this.admins,
    required this.helpdesk,
    required this.inactive,
  });

  final int total;
  final int admins;
  final int helpdesk;
  final int inactive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          _Stat(label: 'TOTAL', value: '$total'),
          const _Divider(),
          _Stat(label: 'ADMIN', value: '$admins'),
          const _Divider(),
          _Stat(label: 'HELPDESK', value: '$helpdesk'),
          const _Divider(),
          _Stat(label: 'NONAKTIF', value: '$inactive'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: AppTextStyles.monoMedium.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.eyebrow.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
    );
  }
}

// ── User row ──────────────────────────────────────────────────────────

class _UserRow extends StatelessWidget {
  const _UserRow({
    super.key,
    required this.user,
    required this.isSelf,
    required this.onManage,
  });

  final UserEntity user;
  final bool isSelf;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final Color fill = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final Color border = dark ? AppColors.borderDark : AppColors.borderLight;
    final BorderRadius radius = BorderRadius.circular(12);
    final String initial =
        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        boxShadow: AppColors.restShadow(dark),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onManage,
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              children: <Widget>[
                // Avatar.
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? theme.colorScheme.primary.withValues(alpha: 0.12)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    initial,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: user.isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + username.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              user.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: user.isActive
                                    ? null
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          if (isSelf) ...<Widget>[
                            const SizedBox(width: 6),
                            _MiniTag(
                              label: 'Anda',
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '@${user.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.monoSmall.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Role + active state.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    RoleChip(role: user.role),
                    const SizedBox(height: 6),
                    if (!user.isActive)
                      _MiniTag(label: 'NONAKTIF', color: theme.colorScheme.error)
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.tertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Aktif',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

/// Public so the row + sheet share one consistent role pill.
class RoleChip extends StatelessWidget {
  const RoleChip({super.key, required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (role) {
      UserRole.admin => AppColors.primary,
      UserRole.helpdesk => AppColors.secondary,
      UserRole.user => AppColors.statusClosed,
    };
    final String label = AppLabels.role[role.wire] ?? role.wire;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ── Manage bottom sheet ───────────────────────────────────────────────

class _ManageSheet extends ConsumerStatefulWidget {
  const _ManageSheet({required this.user, required this.isSelf});

  final UserEntity user;
  final bool isSelf;

  @override
  ConsumerState<_ManageSheet> createState() => _ManageSheetState();
}

class _ManageSheetState extends ConsumerState<_ManageSheet> {
  bool _busy = false;

  Future<void> _setRole(UserRole role) async {
    if (role == widget.user.role || _busy) return;
    setState(() => _busy = true);
    final ({bool ok, String? error}) r = await ref
        .read(userManagementControllerProvider.notifier)
        .setRole(userId: widget.user.id, role: role);
    if (!mounted) return;
    setState(() => _busy = false);
    HapticFeedback.lightImpact();
    _toast(r.ok
        ? 'Peran ${widget.user.fullName} → ${AppLabels.role[role.wire]}'
        : (r.error ?? 'Gagal mengubah peran.'));
    if (r.ok) Navigator.of(context).pop();
  }

  Future<void> _setActive(bool active) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ({bool ok, String? error}) r = await ref
        .read(userManagementControllerProvider.notifier)
        .setActive(userId: widget.user.id, isActive: active);
    if (!mounted) return;
    setState(() => _busy = false);
    HapticFeedback.mediumImpact();
    _toast(r.ok
        ? (active ? 'Akun diaktifkan.' : 'Akun dinonaktifkan.')
        : (r.error ?? 'Gagal memperbarui akun.'));
    if (r.ok) Navigator.of(context).pop();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final UserEntity u = widget.user;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: dark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(u.fullName, style: theme.textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              '@${u.username}',
              style: AppTextStyles.monoSmall.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),

            // ── Role section ──
            Text('Peran', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            if (widget.isSelf)
              _InfoNote(
                icon: Icons.lock_outline,
                text: 'Anda tidak dapat mengubah peran sendiri.',
              )
            else
              Row(
                children: <Widget>[
                  for (final UserRole r in UserRole.values) ...<Widget>[
                    Expanded(
                      child: _RoleOption(
                        role: r,
                        selected: r == u.role,
                        onTap: _busy ? null : () => _setRole(r),
                      ),
                    ),
                    if (r != UserRole.values.last) const SizedBox(width: 8),
                  ],
                ],
              ),
            const SizedBox(height: 22),

            // ── Active section ──
            Text('Status akun', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            if (widget.isSelf)
              _InfoNote(
                icon: Icons.lock_outline,
                text: 'Anda tidak dapat menonaktifkan akun sendiri.',
              )
            else if (u.isActive)
              _ActionButton(
                icon: Icons.block,
                label: 'Nonaktifkan Akun',
                destructive: true,
                busy: _busy,
                onTap: () => _setActive(false),
              )
            else
              _ActionButton(
                icon: Icons.check_circle_outline,
                label: 'Aktifkan Kembali',
                destructive: false,
                busy: _busy,
                onTap: () => _setActive(true),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final String label = AppLabels.role[role.wire] ?? role.wire;
    final IconData icon = switch (role) {
      UserRole.admin => Icons.shield_outlined,
      UserRole.helpdesk => Icons.support_agent_outlined,
      UserRole.user => Icons.person_outline,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: <Widget>[
            Icon(
              icon,
              size: 20,
              color: selected
                  ? primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.destructive,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool destructive;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color =
        destructive ? theme.colorScheme.error : AppColors.tertiary;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        icon: busy
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: 'Akses ditolak',
      subtitle: 'Hanya admin yang dapat mengelola pengguna.',
      icon: Icons.lock_outline,
    );
  }
}
