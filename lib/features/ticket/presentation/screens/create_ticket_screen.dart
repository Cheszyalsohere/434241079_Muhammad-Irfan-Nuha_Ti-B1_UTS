/// Create ticket screen — FR-005.
///
/// Form with title, description, category dropdown, priority
/// dropdown, and optional image attachment (camera or gallery with
/// crop). On success we invalidate every active ticket list scope so
/// the new ticket appears at the top and `pop()` back to the list.
library;

import 'dart:typed_data';

import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../providers/ticket_list_provider.dart';
import '../providers/ticket_providers.dart';
import '../widgets/image_picker_sheet.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  TicketCategory _category = TicketCategory.other;
  TicketPriority _priority = TicketPriority.medium;
  AttachmentResult? _attachment;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    try {
      final AttachmentResult? res = await pickAttachment(context);
      if (!mounted || res == null) return;
      setState(() => _attachment = res);
    } on ValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final Uint8List? bytes = _attachment?.bytes;
    final String? fileName = _attachment?.fileName;

    final Either<Failure, TicketEntity> res =
        await ref.read(createTicketUseCaseProvider).call(
              title: _titleCtrl.text,
              description: _descCtrl.text,
              category: _category,
              priority: _priority,
              attachmentBytes: bytes,
              attachmentFileName: fileName,
            );

    if (!mounted) return;
    setState(() => _submitting = false);

    res.fold(
      (Failure f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message)),
        );
      },
      (TicketEntity t) {
        // Refresh every active scope so the new ticket is visible on
        // return. `invalidate` triggers a re-fetch lazily.
        for (final TicketScope s in TicketScope.values) {
          ref.invalidate(ticketListControllerProvider(s));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tiket ${t.ticketNumber} dibuat.')),
        );
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tiket Baru')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              CustomTextField(
                label: 'Judul',
                controller: _titleCtrl,
                prefixIcon: Icons.title,
                textInputAction: TextInputAction.next,
                validator: Validators.ticketTitle,
                maxLength: AppConstants.maxTitleLength,
                enabled: !_submitting,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Deskripsi',
                controller: _descCtrl,
                prefixIcon: Icons.description_outlined,
                maxLines: 6,
                maxLength: AppConstants.maxDescriptionLength,
                validator: Validators.ticketDescription,
                enabled: !_submitting,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TicketCategory>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: <DropdownMenuItem<TicketCategory>>[
                  for (final TicketCategory c in TicketCategory.values)
                    DropdownMenuItem<TicketCategory>(
                      value: c,
                      child: Text(c.label),
                    ),
                ],
                onChanged: _submitting
                    ? null
                    : (TicketCategory? v) {
                        if (v != null) setState(() => _category = v);
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TicketPriority>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Prioritas',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: <DropdownMenuItem<TicketPriority>>[
                  for (final TicketPriority p in TicketPriority.values)
                    DropdownMenuItem<TicketPriority>(
                      value: p,
                      child: Text(p.label),
                    ),
                ],
                onChanged: _submitting
                    ? null
                    : (TicketPriority? v) {
                        if (v != null) setState(() => _priority = v);
                      },
              ),
              const SizedBox(height: 20),
              Text('Lampiran (opsional)', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              _AttachmentPreview(
                attachment: _attachment,
                onPick: _submitting ? null : _pickAttachment,
                onRemove: _submitting
                    ? null
                    : () => setState(() => _attachment = null),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Kirim Tiket',
                icon: Icons.send,
                onPressed: _submitting ? null : _submit,
                isLoading: _submitting,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({
    required this.attachment,
    required this.onPick,
    required this.onRemove,
  });

  final AttachmentResult? attachment;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (attachment == null) {
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.add_photo_alternate_outlined,
                  size: 32, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 6),
              Text(
                'Tambahkan foto',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            attachment!.bytes,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.black.withValues(alpha: 0.55),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Hapus lampiran',
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: onRemove,
            ),
          ),
        ),
      ],
    );
  }
}
