/// Ticket detail screen — FR-005/FR-006.
///
/// Sections:
///   1. Header       — ticket number, title, status + priority badges,
///                     category, creator + assignee metadata, timestamps.
///   2. Attachment   — tap to open full-screen viewer.
///   3. Description  — original ticket body.
///   4. Timeline     — status changes interleaved with comments,
///                     chronologically ordered.
///   5. Composer     — text field + camera button for replies.
///
/// Helpdesk/admin get two extra controls in the overflow menu:
///   • "Ubah Status" — dialog cycling through TicketStatus values
///   • "Tugaskan"    — dialog picking from the cached helpdesk staff list
///
// `RadioListTile.groupValue`/`onChanged` are deprecated in favor of a
// `RadioGroup` ancestor; we keep the per-tile API here for terseness
// in the status/assign dialogs and silence the lint.
// ignore_for_file: deprecated_member_use
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../../domain/usecases/get_ticket_detail_usecase.dart';
import '../providers/ticket_detail_provider.dart';
import '../providers/ticket_list_provider.dart';
import '../widgets/comment_bubble.dart';
import '../widgets/image_picker_sheet.dart';

class TicketDetailScreen extends ConsumerWidget {
  const TicketDetailScreen({required this.ticketId, super.key});

  final String ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TicketDetail> async =
        ref.watch(ticketDetailControllerProvider(ticketId));
    final UserEntity? me = ref.watch(currentUserProvider).valueOrNull;
    final bool isAdmin = me?.role.isAdmin ?? false;
    final TicketEntity? ticket = async.valueOrNull?.ticket;
    final TicketStatus? status = ticket?.status;
    final bool isAssignee = ticket?.assignedTo != null &&
        ticket!.assignedTo == me?.id;

    // Status is driven by workflow actions only (no manual editing):
    //   • Admin "Terima"   : open → assigned
    //   • Admin "Tugaskan" : assigned → in_progress (also sets assignee)
    //   • Helpdesk "Selesai": in_progress → closed
    final bool canAccept = isAdmin && status == TicketStatus.open;
    final bool canAssign = isAdmin &&
        (status == TicketStatus.assigned || status == TicketStatus.inProgress);
    final bool canFinish =
        (isAdmin || isAssignee) && status == TicketStatus.inProgress;
    // Delete: admin or the ticket's own creator (BR-002.8).
    final bool canDelete =
        ticket != null && (isAdmin || ticket.createdBy == me?.id);
    final bool showMenu = async.hasValue &&
        (canAccept || canAssign || canFinish || canDelete);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Prefer the navigation stack when there's something to
            // pop; on web (or after a deep link) the user may have
            // landed here directly, in which case fall back to the
            // dashboard so they're never stuck.
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
        title: async.when(
          data: (TicketDetail d) => Text(d.ticket.ticketNumber),
          loading: () => const Text('Memuat...'),
          error: (_, __) => const Text('Detail Tiket'),
        ),
        actions: <Widget>[
          if (showMenu)
            PopupMenuButton<_StaffAction>(
              icon: const Icon(Icons.more_vert),
              onSelected: (_StaffAction a) =>
                  _onStaffAction(context, ref, a, ticket!),
              itemBuilder: (BuildContext ctx) => <PopupMenuEntry<_StaffAction>>[
                if (canAccept)
                  const PopupMenuItem<_StaffAction>(
                    value: _StaffAction.accept,
                    child: ListTile(
                      leading: Icon(Icons.inbox_outlined),
                      title: Text('Terima Tiket'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                if (canAssign)
                  PopupMenuItem<_StaffAction>(
                    value: _StaffAction.assign,
                    child: ListTile(
                      leading: const Icon(Icons.person_add_alt),
                      title: Text(
                        status == TicketStatus.inProgress
                            ? 'Tugaskan Ulang'
                            : 'Tugaskan ke Helpdesk',
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                if (canFinish)
                  PopupMenuItem<_StaffAction>(
                    value: _StaffAction.finish,
                    child: ListTile(
                      leading: Icon(Icons.check_circle_outline,
                          color: AppColors.statusClosed),
                      title: const Text('Tandai Selesai'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                if (canDelete) ...<PopupMenuEntry<_StaffAction>>[
                  if (canAccept || canAssign || canFinish)
                    const PopupMenuDivider(),
                  PopupMenuItem<_StaffAction>(
                    value: _StaffAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline,
                          color: Theme.of(ctx).colorScheme.error),
                      title: Text(
                        'Hapus Tiket',
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingIndicator(message: 'Memuat tiket...'),
        error: (Object e, _) => _ErrorRetry(
          message: e.toString(),
          onRetry: () => ref.invalidate(
            ticketDetailControllerProvider(ticketId),
          ),
        ),
        data: (TicketDetail d) => _DetailBody(
          detail: d,
          me: me,
          onRefresh: () => ref
              .read(ticketDetailControllerProvider(ticketId).notifier)
              .refresh(),
        ),
      ),
    );
  }

  Future<void> _onStaffAction(
    BuildContext context,
    WidgetRef ref,
    _StaffAction action,
    TicketEntity ticket,
  ) async {
    switch (action) {
      case _StaffAction.accept:
        await _applyStatus(
          context,
          ref,
          ticket,
          TicketStatus.assigned,
          'Tiket diterima — silakan tugaskan ke helpdesk.',
        );
      case _StaffAction.finish:
        await _confirmFinish(context, ref, ticket);
      case _StaffAction.assign:
        final AsyncValue<List<UserEntity>> staffAsync =
            ref.read(helpdeskStaffProvider);
        final List<UserEntity> staff = staffAsync.valueOrNull ??
            await ref.read(helpdeskStaffProvider.future);
        if (!context.mounted) return;
        final _AssignChoice? choice = await showDialog<_AssignChoice>(
          context: context,
          builder: (BuildContext ctx) => _AssignDialog(
            currentAssigneeId: ticket.assignedTo,
            staff: staff,
          ),
        );
        if (choice == null) return;
        final bool ok = await ref
            .read(ticketDetailControllerProvider(ticket.id).notifier)
            .assign(choice.userId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ok
                    ? (choice.userId == null
                        ? 'Assignment dilepas.'
                        : 'Tiket ditugaskan.')
                    : 'Gagal menugaskan tiket.',
              ),
            ),
          );
          for (final TicketScope s in TicketScope.values) {
            ref.invalidate(ticketListControllerProvider(s));
          }
        }
      case _StaffAction.delete:
        await _confirmAndDelete(context, ref, ticket);
    }
  }

  /// Apply a workflow status change, surface feedback, and refresh every
  /// ticket-list scope so the new status shows across the app.
  Future<void> _applyStatus(
    BuildContext context,
    WidgetRef ref,
    TicketEntity ticket,
    TicketStatus newStatus,
    String successMsg,
  ) async {
    final bool ok = await ref
        .read(ticketDetailControllerProvider(ticket.id).notifier)
        .updateStatus(newStatus);
    if (!context.mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      for (final TicketScope s in TicketScope.values) {
        ref.invalidate(ticketListControllerProvider(s));
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? successMsg : 'Gagal memperbarui status.')),
    );
  }

  /// Confirm before closing a ticket via the helpdesk "Selesai" action.
  Future<void> _confirmFinish(
    BuildContext context,
    WidgetRef ref,
    TicketEntity ticket,
  ) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Tandai Selesai?'),
        content: Text(
          'Tiket ${ticket.ticketNumber} akan ditutup (status Ditutup). '
          'Pastikan pekerjaan sudah benar-benar selesai.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _applyStatus(
      context,
      ref,
      ticket,
      TicketStatus.closed,
      'Tiket ditandai selesai.',
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    TicketEntity ticket,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Hapus Tiket?'),
        content: Text(
          'Tiket ${ticket.ticketNumber} beserta seluruh komentar dan '
          'riwayatnya akan dihapus permanen. Tindakan ini tidak dapat '
          'dibatalkan.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final ({bool ok, String? error}) r = await ref
        .read(ticketDetailControllerProvider(ticket.id).notifier)
        .delete();
    if (!context.mounted) return;

    if (r.ok) {
      HapticFeedback.mediumImpact();
      // The deleted ticket must disappear from every list scope.
      for (final TicketScope s in TicketScope.values) {
        ref.invalidate(ticketListControllerProvider(s));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tiket ${ticket.ticketNumber} dihapus.')),
      );
      // Leave the now-dead detail screen.
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.tickets);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.error ?? 'Gagal menghapus tiket.')),
      );
    }
  }
}

enum _StaffAction { accept, assign, finish, delete }

/// ──────────────────────────────────────────────────────────────────────
/// Body: header + description + timeline + composer
/// ──────────────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({
    required this.detail,
    required this.me,
    required this.onRefresh,
  });

  final TicketDetail detail;
  final UserEntity? me;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  final TextEditingController _replyCtrl = TextEditingController();
  AttachmentResult? _replyAttachment;
  bool _sending = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReplyAttachment() async {
    try {
      final AttachmentResult? r = await pickAttachment(context);
      if (!mounted || r == null) return;
      setState(() => _replyAttachment = r);
    } on ValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _sendReply() async {
    final String text = _replyCtrl.text.trim();
    if (text.isEmpty && _replyAttachment == null) return;

    final String? err = text.isEmpty ? null : Validators.comment(text);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }

    setState(() => _sending = true);
    final Uint8List? bytes = _replyAttachment?.bytes;
    final String? name = _replyAttachment?.fileName;

    final bool ok = await ref
        .read(ticketDetailControllerProvider(widget.detail.ticket.id).notifier)
        .addComment(
          message: text,
          attachmentBytes: bytes,
          attachmentFileName: name,
        );

    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) {
        _replyCtrl.clear();
        _replyAttachment = null;
      }
    });

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim balasan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TicketDetail d = widget.detail;
    // Comments are sorted oldest -> newest by the datasource. We
    // render them as a chat-style activity feed beneath the dedicated
    // "Timeline Status" expansion above so the two sections don't
    // duplicate the same status events.
    final List<CommentEntity> comments = d.comments;

    return Column(
      children: <Widget>[
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ResponsiveCenter(
              child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: <Widget>[
                _HeaderCard(ticket: d.ticket),
                if (d.ticket.attachmentUrl != null)
                  _FullWidthAttachment(url: d.ticket.attachmentUrl!),
                _DescriptionCard(description: d.ticket.description),
                const SizedBox(height: 8),
                _TimelineStatusSection(
                  ticket: d.ticket,
                  history: d.history,
                ),
                const SizedBox(height: 8),
                const _SectionHeader('Aktivitas'),
                if (comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Text(
                      'Belum ada komentar.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  )
                else
                  for (final CommentEntity c in comments)
                    CommentBubble(
                      comment: c,
                      isMine: c.userId == widget.me?.id,
                    ),
                const SizedBox(height: 80),
              ],
            ),
            ),
          ),
        ),
        _Composer(
          controller: _replyCtrl,
          attachment: _replyAttachment,
          onPickAttachment: _sending ? null : _pickReplyAttachment,
          onClearAttachment: _sending
              ? null
              : () => setState(() => _replyAttachment = null),
          onSend: _sending ? null : _sendReply,
          sending: _sending,
        ),
      ],
    );
  }

}

/// ──────────────────────────────────────────────────────────────────────
/// Header / description / attachment tiles
/// ──────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.ticket});
  final TicketEntity ticket;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              ticket.ticketNumber,
              style: AppTextStyles.monoSmall.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(ticket.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                StatusBadge(value: ticket.status.wire, kind: BadgeKind.status),
                StatusBadge(
                  value: ticket.priority.wire,
                  kind: BadgeKind.priority,
                ),
                _MetaChip(
                  icon: Icons.category_outlined,
                  label: ticket.category.label,
                ),
              ],
            ),
            const Divider(height: 24),
            _MetaLine(
              icon: Icons.person_outline,
              label: 'Pemohon',
              value: ticket.createdByProfile?.fullName ?? '—',
            ),
            const SizedBox(height: 6),
            _MetaLine(
              icon: Icons.support_agent,
              label: 'Ditugaskan',
              value: ticket.assignedToProfile?.fullName ?? 'Belum ditugaskan',
            ),
            const SizedBox(height: 6),
            _MetaLine(
              icon: Icons.schedule,
              label: 'Dibuat',
              value: DateFormatter.formatDateTime(ticket.createdAt),
            ),
            const SizedBox(height: 6),
            _MetaLine(
              icon: Icons.update,
              label: 'Diperbarui',
              value: DateFormatter.formatDateTime(ticket.updatedAt),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.description});
  final String description;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Deskripsi', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(description, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Entry point to the dedicated Tracking screen (SRS §5.8). Shows a
/// compact summary (change count) and navigates to the full status
/// journey + workflow stepper on tap.
class _TimelineStatusSection extends StatelessWidget {
  const _TimelineStatusSection({
    required this.ticket,
    required this.history,
  });

  final TicketEntity ticket;
  final List<StatusHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Icon(Icons.timeline, color: theme.colorScheme.primary),
        title: Text('Tracking Status', style: theme.textTheme.titleSmall),
        subtitle: Text(
          history.isEmpty
              ? 'Lihat perjalanan status tiket'
              : '${history.length} perubahan • lihat tracking lengkap',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        onTap: () => context.push('/tickets/${ticket.id}/tracking'),
      ),
    );
  }
}

class _FullWidthAttachment extends StatelessWidget {
  const _FullWidthAttachment({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: () => _openFullScreen(context, url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: url,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => const SizedBox(
              height: 200,
              child: Center(
                child:
                    SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 120,
              alignment: Alignment.center,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      ),
    );
  }
}

void _openFullScreen(BuildContext context, String url) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (BuildContext ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: InteractiveViewer(
            child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
          ),
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.eyebrow.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// ──────────────────────────────────────────────────────────────────────
/// Composer
/// ──────────────────────────────────────────────────────────────────────

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.attachment,
    required this.onPickAttachment,
    required this.onClearAttachment,
    required this.onSend,
    required this.sending,
  });

  final TextEditingController controller;
  final AttachmentResult? attachment;
  final VoidCallback? onPickAttachment;
  final VoidCallback? onClearAttachment;
  final VoidCallback? onSend;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: ResponsiveCenter(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (attachment != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 48, right: 8),
                child: _AttachmentThumb(
                  bytes: attachment!.bytes,
                  onRemove: onClearAttachment,
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                IconButton(
                  tooltip: 'Lampirkan foto',
                  onPressed: onPickAttachment,
                  icon: const Icon(Icons.camera_alt_outlined),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: AppConstants.maxCommentLength,
                    decoration: const InputDecoration(
                      hintText: 'Tulis balasan...',
                      isDense: true,
                      counterText: '',
                    ),
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Kirim',
                  onPressed: onSend,
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _AttachmentThumb extends StatelessWidget {
  const _AttachmentThumb({required this.bytes, this.onRemove});
  final Uint8List bytes;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            width: 120,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: Material(
            color: Colors.black.withValues(alpha: 0.55),
            shape: const CircleBorder(),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 22,
                height: 22,
              ),
              tooltip: 'Hapus',
              onPressed: onRemove,
              icon: const Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ──────────────────────────────────────────────────────────────────────
/// Staff dialogs
/// ──────────────────────────────────────────────────────────────────────

/// Small value carrier for the assign dialog. `userId = null` means
/// "unassign" — distinguishable from a dismissal (which returns null
/// from the whole dialog).
class _AssignChoice {
  const _AssignChoice(this.userId);
  final String? userId;
}

class _AssignDialog extends StatelessWidget {
  const _AssignDialog({
    required this.currentAssigneeId,
    required this.staff,
  });

  final String? currentAssigneeId;
  final List<UserEntity> staff;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tugaskan Tiket'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RadioListTile<String?>(
              value: null,
              groupValue: currentAssigneeId,
              title: const Text('Belum ditugaskan'),
              onChanged: (_) =>
                  Navigator.of(context).pop(const _AssignChoice(null)),
            ),
            for (final UserEntity u in staff)
              RadioListTile<String?>(
                value: u.id,
                groupValue: currentAssigneeId,
                title: Text(u.fullName),
                subtitle: Text('@${u.username} • ${u.role.name}'),
                onChanged: (_) =>
                    Navigator.of(context).pop(_AssignChoice(u.id)),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
