/// Chat-style comment bubble. Renders the author's avatar/initials,
/// name, relative timestamp, message body, and an optional tap-to-open
/// image attachment. The bubble aligns right when [isMine] is true so
/// readers can quickly see their own replies.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/comment_entity.dart';

class CommentBubble extends StatelessWidget {
  const CommentBubble({
    required this.comment,
    required this.isMine,
    this.onAttachmentTap,
    super.key,
  });

  final CommentEntity comment;
  final bool isMine;
  final void Function(String url)? onAttachmentTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color bubbleColor = isMine
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final Color onBubble = isMine
        ? scheme.onPrimaryContainer
        : scheme.onSurface;

    final UserEntity? author = comment.userProfile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          if (!isMine) _Avatar(user: author),
          if (!isMine) const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      author?.fullName ?? 'Pengguna',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormatter.relative(comment.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft:
                          Radius.circular(isMine ? 14 : 4),
                      bottomRight:
                          Radius.circular(isMine ? 4 : 14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (comment.attachmentUrl != null) ...<Widget>[
                        _AttachmentThumb(
                          url: comment.attachmentUrl!,
                          onTap: onAttachmentTap,
                        ),
                        if (comment.message.isNotEmpty)
                          const SizedBox(height: 8),
                      ],
                      if (comment.message.isNotEmpty)
                        Text(
                          comment.message,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: onBubble),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMine) const SizedBox(width: 10),
          if (isMine) _Avatar(user: author),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.user});
  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String initials = () {
      final String name = user?.fullName.trim() ?? '?';
      if (name.isEmpty) return '?';
      final List<String> parts = name
          .split(RegExp(r'\s+'))
          .where((String p) => p.isNotEmpty)
          .toList();
      if (parts.length == 1) {
        return parts.first.characters.first.toUpperCase();
      }
      return (parts.first.characters.first + parts.last.characters.first)
          .toUpperCase();
    }();

    return CircleAvatar(
      radius: 16,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      backgroundImage:
          (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
              ? NetworkImage(user!.avatarUrl!)
              : null,
      child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
          ? Text(
              initials,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );
  }
}

class _AttachmentThumb extends StatelessWidget {
  const _AttachmentThumb({required this.url, this.onTap});
  final String url;
  final void Function(String url)? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 200,
          height: 160,
          fit: BoxFit.cover,
          placeholder: (BuildContext _, String __) => const SizedBox(
            width: 200,
            height: 160,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (BuildContext _, String __, Object ___) => Container(
            width: 200,
            height: 80,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}
