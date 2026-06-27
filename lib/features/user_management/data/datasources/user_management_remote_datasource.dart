/// Remote datasource for admin user management — reads/writes the
/// `profiles` table via Supabase. Throws [AppException] subtypes; the
/// repository maps them to [Failure].
///
/// Note: profile rows do not carry the auth email (that lives on
/// `auth.users`), so the listed [UserModel]s have a null email. The
/// management UI keys off full name + username instead.
library;

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/config/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../auth/data/models/user_model.dart';

class UserManagementRemoteDataSource {
  UserManagementRemoteDataSource(this._client);

  final sb.SupabaseClient _client;

  /// List all profiles, newest first. [search] (optional) filters by
  /// full name or username, case-insensitive.
  Future<List<UserModel>> getUsers({String? search}) async {
    try {
      final sb.SupabaseQueryBuilder table =
          _client.from(AppConstants.tblProfiles);
      sb.PostgrestFilterBuilder<List<Map<String, dynamic>>> query =
          table.select();

      final String? q = search?.trim();
      if (q != null && q.isNotEmpty) {
        // OR across full_name / username with ILIKE wildcards.
        query = query.or('full_name.ilike.%$q%,username.ilike.%$q%');
      }

      final List<Map<String, dynamic>> rows =
          await query.order('created_at', ascending: false);
      return rows.map(UserModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message, cause: e);
    } catch (e) {
      throw ServerException('Gagal memuat daftar pengguna.', cause: e);
    }
  }

  /// Update [userId]'s role. Returns the updated row.
  Future<UserModel> updateRole({
    required String userId,
    required String role,
  }) async {
    return _updateAndReturn(userId, <String, dynamic>{'role': role});
  }

  /// Set [userId]'s active flag. Returns the updated row.
  Future<UserModel> setActive({
    required String userId,
    required bool isActive,
  }) async {
    return _updateAndReturn(userId, <String, dynamic>{'is_active': isActive});
  }

  Future<UserModel> _updateAndReturn(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(AppConstants.tblProfiles)
          .update(patch)
          .eq('id', userId)
          .select()
          .single();
      return UserModel.fromJson(row);
    } on sb.PostgrestException catch (e) {
      // RLS rejection surfaces as a permission-ish error.
      if (e.code == '42501' || e.message.toLowerCase().contains('policy')) {
        throw ServerException(
          'Anda tidak memiliki izin untuk tindakan ini.',
          cause: e,
        );
      }
      throw ServerException(e.message, cause: e);
    } catch (e) {
      throw ServerException('Gagal memperbarui pengguna.', cause: e);
    }
  }
}
