/// Remote datasource for profile reads and mutations.
///
/// Wraps Supabase Postgrest (`profiles` table), Storage
/// (`ticket-attachments` bucket — `avatars/<uid>.jpg` path), and
/// `auth.updateUser` for password changes. Throws domain-agnostic
/// [AppException]s; the repository maps these to [Failure].
///
/// We reuse [UserModel] from the auth feature (same `profiles` row
/// shape) instead of declaring a duplicate model — avatar updates flow
/// through the same entity that powers `currentUserProvider`.
library;

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/config/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../auth/data/models/user_model.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._client);

  final sb.SupabaseClient _client;

  // ── Reads ──────────────────────────────────────────────────────────

  /// Fetch the profile row for [userId]. Augments the raw row with the
  /// caller's session email so `UserModel.toEntity()` produces a fully
  /// populated [UserEntity].
  Future<UserModel> fetchProfile(String userId) async {
    try {
      final Map<String, dynamic>? row = await _client
          .from(AppConstants.tblProfiles)
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null) {
        throw const ServerException('Profil tidak ditemukan.');
      }
      final String email = _client.auth.currentUser?.email ?? '';
      return UserModel.fromJson(<String, dynamic>{...row, 'email': email});
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message, cause: e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal memuat profil.', cause: e);
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────

  /// Update display fields. Returns the refreshed [UserModel].
  Future<UserModel> updateProfile({
    required String userId,
    required String fullName,
    required String username,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(AppConstants.tblProfiles)
          .update(<String, dynamic>{
            'full_name': fullName,
            'username': username,
          })
          .eq('id', userId)
          .select()
          .single();
      final String email = _client.auth.currentUser?.email ?? '';
      return UserModel.fromJson(<String, dynamic>{...row, 'email': email});
    } on sb.PostgrestException catch (e) {
      // Username unique constraint.
      if (e.code == '23505') {
        throw const ServerException(
          'Username sudah terpakai. Pilih yang lain.',
        );
      }
      if (e.code == '42501') {
        throw const ServerException(
          'Anda tidak memiliki izin untuk mengubah profil ini.',
        );
      }
      throw ServerException(e.message, cause: e);
    } catch (e) {
      throw ServerException('Gagal memperbarui profil.', cause: e);
    }
  }

  /// Upload [bytes] as the user's avatar at `avatars/<userId>.<ext>`
  /// and return its public URL. Re-uploads use `upsert: true` so the
  /// same path can be overwritten on every change.
  ///
  /// We append a cache-buster (`?v=<ts>`) to the returned URL so
  /// `cached_network_image` immediately re-fetches instead of serving
  /// the stale previous bytes from disk.
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    String extension = 'jpg',
  }) async {
    try {
      final String safeExt = extension.toLowerCase().replaceAll('.', '');
      final String path = 'avatars/$userId.$safeExt';
      await _client.storage
          .from(AppConstants.bucketTicketAttachments)
          .uploadBinary(
            path,
            bytes,
            fileOptions: sb.FileOptions(
              contentType: _inferContentType(safeExt),
              upsert: true,
            ),
          );
      final String publicUrl = _client.storage
          .from(AppConstants.bucketTicketAttachments)
          .getPublicUrl(path);
      final int ts = DateTime.now().millisecondsSinceEpoch;
      return '$publicUrl?v=$ts';
    } on sb.StorageException catch (e) {
      throw ServerException(
        'Gagal mengunggah avatar: ${e.message}',
        cause: e,
      );
    } catch (e) {
      throw ServerException('Gagal mengunggah avatar.', cause: e);
    }
  }

  /// Persist the new avatar URL onto the `profiles` row. Pass `null` to
  /// clear the avatar.
  Future<UserModel> updateAvatarUrl({
    required String userId,
    required String? avatarUrl,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(AppConstants.tblProfiles)
          .update(<String, dynamic>{'avatar_url': avatarUrl})
          .eq('id', userId)
          .select()
          .single();
      final String email = _client.auth.currentUser?.email ?? '';
      return UserModel.fromJson(<String, dynamic>{...row, 'email': email});
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message, cause: e);
    } catch (e) {
      throw ServerException('Gagal menyimpan avatar.', cause: e);
    }
  }

  /// Update the current user's password via Supabase Auth. Supabase
  /// does not require re-auth; the existing access token is used.
  Future<void> changePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        sb.UserAttributes(password: newPassword),
      );
    } on sb.AuthException catch (e) {
      final String m = e.message.toLowerCase();
      if (m.contains('password should be at least')) {
        throw AuthException(
          'Kata sandi minimal ${AppConstants.minPasswordLength} karakter.',
        );
      }
      if (m.contains('same as') || m.contains('different')) {
        throw const AuthException(
          'Kata sandi baru harus berbeda dari yang lama.',
        );
      }
      throw AuthException(e.message);
    } catch (e) {
      throw ServerException('Gagal memperbarui kata sandi.', cause: e);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────

  String _inferContentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
