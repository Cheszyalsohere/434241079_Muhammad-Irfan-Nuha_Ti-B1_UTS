/// Remote datasource for tickets, comments, and status history. Wraps
/// Supabase PostgREST + Storage calls and converts raw Supabase
/// exceptions into our [AppException] hierarchy so the repository can
/// stay provider-agnostic.
///
/// Embed aliases returned by list/detail reads:
///   • tickets            → created_by_profile, assigned_to_profile
///   • ticket_comments    → user_profile
///   • ticket_status_hist → changed_by_profile
///
/// None of these embeds include `email` (that lives on `auth.users`),
/// so the returned [UserModel]s will have a null email — fine for
/// avatar / name / role rendering, which is all we need for nested
/// profiles.
library;

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/config/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../models/comment_model.dart';
import '../models/status_history_model.dart';
import '../models/ticket_model.dart';

class TicketRemoteDataSource {
  TicketRemoteDataSource(this._client);

  final sb.SupabaseClient _client;

  // ── Column selectors ───────────────────────────────────────────────

  static const String _profileCols =
      'id, username, full_name, role, avatar_url, created_at';

  static const String _ticketSelect = '''
*,
created_by_profile:profiles!created_by($_profileCols),
assigned_to_profile:profiles!assigned_to($_profileCols)
''';

  static const String _commentSelect = '''
*,
user_profile:profiles!user_id($_profileCols)
''';

  static const String _historySelect = '''
*,
changed_by_profile:profiles!changed_by($_profileCols)
''';

  // ── Reads ──────────────────────────────────────────────────────────

  Future<List<TicketModel>> listTickets({
    required int page,
    required int pageSize,
    TicketScope scope = TicketScope.all,
    TicketStatus? status,
    String? search,
  }) async {
    try {
      final String? uid = _client.auth.currentUser?.id;
      if (uid == null) {
        throw const AuthException('Sesi tidak valid. Silakan masuk kembali.');
      }

      dynamic query = _client
          .from(AppConstants.tblTickets)
          .select(_ticketSelect);

      if (scope == TicketScope.mine) {
        query = query.eq('created_by', uid);
      } else if (scope == TicketScope.assignedToMe) {
        query = query.eq('assigned_to', uid);
      }

      if (status != null) {
        query = query.eq('status', status.wire);
      }

      final String trimmed = (search ?? '').trim();
      if (trimmed.isNotEmpty) {
        // Search both title and ticket number.
        final String esc = trimmed.replaceAll('%', r'\%').replaceAll(',', ' ');
        query = query.or('title.ilike.%$esc%,ticket_number.ilike.%$esc%');
      }

      final int from = page * pageSize;
      final int to = from + pageSize - 1;
      // Chained `dynamic` loses the `PostgrestTransformBuilder` typing,
      // so we cast the terminal result back to `List`.
      final dynamic raw = await query
          .order('updated_at', ascending: false)
          .range(from, to);
      final List<dynamic> rows = raw as List<dynamic>;

      return rows
          .map((dynamic r) =>
              TicketModel.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList(growable: false);
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message, cause: e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal memuat daftar tiket.', cause: e);
    }
  }

  Future<TicketModel> getTicketById(String id) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(AppConstants.tblTickets)
          .select(_ticketSelect)
          .eq('id', id)
          .single();
      return TicketModel.fromJson(Map<String, dynamic>.from(row));
    } on sb.PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const ServerException('Tiket tidak ditemukan.');
      }
      throw ServerException(e.message, cause: e);
    } catch (e) {
      throw ServerException('Gagal memuat tiket.', cause: e);
    }
  }

  Future<List<CommentModel>> listComments(String ticketId) async {
    try {
      final List<dynamic> rows = await _client
          .from(AppConstants.tblTicketComments)
          .select(_commentSelect)
          .eq('ticket_id', ticketId)
          .order('created_at');
      return rows
          .map((dynamic r) =>
              CommentModel.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList(growable: false);
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message, cause: e);
    } catch (e) {
      throw ServerException('Gagal memuat komentar.', cause: e);
    }
  }

  Future<List<StatusHistoryModel>> listStatusHistory(String ticketId) async {
    try {
      final List<dynamic> rows = await _client
          .from(AppConstants.tblTicketStatusHistory)
          .select(_historySelect)
          .eq('ticket_id', ticketId)
          .order('created_at');
      return rows
          .map((dynamic r) =>
              StatusHistoryModel.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList(growable: false);
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message, cause: e);
    } catch (e) {
      throw ServerException('Gagal memuat riwayat status.', cause: e);
    }
  }

  Future<List<Map<String, dynamic>>> listHelpdeskStaff() async {
    try {
      final List<dynamic> rows = await _client
          .from(AppConstants.tblProfiles)
          .select(_profileCols)
          .inFilter('role', <String>['helpdesk', 'admin'])
          .order('full_name');
      return rows
          .map((dynamic r) => Map<String, dynamic>.from(r as Map))
          .toList(growable: false);
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message, cause: e);
    } catch (e) {
      throw ServerException('Gagal memuat daftar helpdesk.', cause: e);
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────

  Future<TicketModel> createTicket({
    required String title,
    required String description,
    required TicketCategory category,
    required TicketPriority priority,
    String? attachmentUrl,
  }) async {
    try {
      final String? uid = _client.auth.currentUser?.id;
      if (uid == null) {
        throw const AuthException('Sesi tidak valid. Silakan masuk kembali.');
      }

      final Map<String, dynamic> row = await _client
          .from(AppConstants.tblTickets)
          .insert(<String, dynamic>{
            'title': title,
            'description': description,
            'category': category.wire,
            'priority': priority.wire,
            'status': TicketStatus.open.wire,
            'attachment_url': attachmentUrl,
            'created_by': uid,
          })
          .select(_ticketSelect)
          .single();
      return TicketModel.fromJson(Map<String, dynamic>.from(row));
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message, cause: e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal membuat tiket.', cause: e);
    }
  }

  Future<TicketModel> updateTicketStatus({
    required String ticketId,
    required TicketStatus newStatus,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(AppConstants.tblTickets)
          .update(<String, dynamic>{'status': newStatus.wire})
          .eq('id', ticketId)
          .select(_ticketSelect)
          .single();
      return TicketModel.fromJson(Map<String, dynamic>.from(row));
    } on sb.PostgrestException catch (e) {
      if (e.code == '42501') {
        throw const ServerException(
          'Anda tidak memiliki izin untuk mengubah status tiket ini.',
        );
      }
      throw ServerException(e.message, cause: e);
    } catch (e) {
      throw ServerException('Gagal mengubah status tiket.', cause: e);
    }
  }

  Future<TicketModel> assignTicket({
    required String ticketId,
    required String? assigneeId,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(AppConstants.tblTickets)
          .update(<String, dynamic>{'assigned_to': assigneeId})
          .eq('id', ticketId)
          .select(_ticketSelect)
          .single();
      return TicketModel.fromJson(Map<String, dynamic>.from(row));
    } on sb.PostgrestException catch (e) {
      if (e.code == '42501') {
        throw const ServerException(
          'Anda tidak memiliki izin untuk menugaskan tiket ini.',
        );
      }
      throw ServerException(e.message, cause: e);
    } catch (e) {
      throw ServerException('Gagal menugaskan tiket.', cause: e);
    }
  }

  Future<CommentModel> addComment({
    required String ticketId,
    required String message,
    String? attachmentUrl,
  }) async {
    try {
      final String? uid = _client.auth.currentUser?.id;
      if (uid == null) {
        throw const AuthException('Sesi tidak valid. Silakan masuk kembali.');
      }
      final Map<String, dynamic> row = await _client
          .from(AppConstants.tblTicketComments)
          .insert(<String, dynamic>{
            'ticket_id': ticketId,
            'user_id': uid,
            'message': message,
            'attachment_url': attachmentUrl,
          })
          .select(_commentSelect)
          .single();
      return CommentModel.fromJson(Map<String, dynamic>.from(row));
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message, cause: e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal mengirim komentar.', cause: e);
    }
  }

  // ── Storage ────────────────────────────────────────────────────────

  /// Upload an image attachment to the `ticket-attachments` bucket and
  /// return its public URL. The path shape is
  /// `<uid>/<subfolder>/<timestamp>-<fileName>` so RLS-style folder
  /// policies (if later enabled) can match on the first segment.
  Future<String> uploadAttachment({
    required Uint8List bytes,
    required String fileName,
    required String subfolder,
  }) async {
    try {
      final String? uid = _client.auth.currentUser?.id;
      if (uid == null) {
        throw const AuthException('Sesi tidak valid. Silakan masuk kembali.');
      }
      final String safeName = fileName
          .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
          .toLowerCase();
      final int ts = DateTime.now().millisecondsSinceEpoch;
      final String path = '$uid/$subfolder/$ts-$safeName';

      await _client.storage
          .from(AppConstants.bucketTicketAttachments)
          .uploadBinary(
            path,
            bytes,
            fileOptions: sb.FileOptions(
              contentType: _inferContentType(safeName),
              upsert: false,
            ),
          );
      return _client.storage
          .from(AppConstants.bucketTicketAttachments)
          .getPublicUrl(path);
    } on sb.StorageException catch (e) {
      throw ServerException(
        'Gagal mengunggah lampiran: ${e.message}',
        cause: e,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal mengunggah lampiran.', cause: e);
    }
  }

  String _inferContentType(String name) {
    final String lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
