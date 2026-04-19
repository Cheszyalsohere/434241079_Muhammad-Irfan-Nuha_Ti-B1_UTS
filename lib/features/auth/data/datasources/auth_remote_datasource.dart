/// Remote datasource wrapping Supabase Auth + the `profiles` table.
///
/// Throws domain-agnostic [AppException] subtypes (from
/// `core/errors/exceptions.dart`); the repository maps these to
/// `Failure` for the presentation layer. Never throws raw Supabase
/// exceptions to upper layers.
library;

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/config/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final sb.SupabaseClient _client;

  sb.GoTrueClient get _auth => _client.auth;

  // ── Reads ──────────────────────────────────────────────────────────

  /// Returns the active session, or `null` when signed out.
  sb.Session? currentSession() => _auth.currentSession;

  /// Stream of auth state events (sign-in, sign-out, token refresh).
  Stream<sb.AuthState> onAuthStateChange() => _auth.onAuthStateChange;

  /// Fetch the profile row for [userId], augmented with the user's
  /// [email] from `auth.users` so the resulting [UserModel] is complete.
  /// Returns `null` if no profile row exists (which should never happen
  /// — the `handle_new_auth_user` trigger guarantees one row per auth
  /// user).
  Future<UserModel?> fetchProfile({
    required String userId,
    required String email,
  }) async {
    try {
      final Map<String, dynamic>? row = await _client
          .from(AppConstants.tblProfiles)
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return null;
      return UserModel.fromJson(<String, dynamic>{...row, 'email': email});
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message, cause: e);
    } catch (e) {
      throw ServerException('Gagal memuat profil pengguna.', cause: e);
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────

  /// Sign in with email + password.
  Future<sb.AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithPassword(email: email, password: password);
    } on sb.AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw ServerException('Gagal masuk. Coba lagi.', cause: e);
    }
  }

  /// Create a new account. The `username`/`fullName` are forwarded as
  /// `raw_user_meta_data` so the DB trigger seeds the profile row.
  Future<sb.AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    try {
      return await _auth.signUp(
        email: email,
        password: password,
        data: <String, dynamic>{
          'username': username,
          'full_name': fullName,
        },
      );
    } on sb.AuthException catch (e) {
      throw _mapAuthException(e);
    } on sb.PostgrestException catch (e) {
      // Trigger ran but profile insert failed (e.g. duplicate username).
      if (e.code == '23505') {
        throw const AuthException('Username sudah terpakai. Pilih yang lain.');
      }
      throw ServerException(e.message, cause: e);
    } catch (e) {
      throw ServerException('Gagal membuat akun. Coba lagi.', cause: e);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw ServerException('Gagal keluar dari sesi.', cause: e);
    }
  }

  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.resetPasswordForEmail(email);
    } on sb.AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw ServerException(
        'Gagal mengirim email reset kata sandi.',
        cause: e,
      );
    }
  }

  // ── Mapping ────────────────────────────────────────────────────────

  /// Translate Supabase auth errors into our [AuthException] with
  /// Indonesian copy. We match on the message because Supabase 2.8.x
  /// does not expose stable error codes on its `AuthException`.
  AuthException _mapAuthException(sb.AuthException e) {
    final String m = e.message.toLowerCase();
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return const AuthException('Email atau kata sandi salah.');
    }
    if (m.contains('already registered') || m.contains('user already')) {
      return const AuthException('Email sudah terdaftar.');
    }
    if (m.contains('email not confirmed')) {
      return const AuthException('Email belum dikonfirmasi.');
    }
    if (m.contains('email rate limit')) {
      return const AuthException(
        'Terlalu banyak permintaan. Coba lagi beberapa saat lagi.',
      );
    }
    if (m.contains('password should be at least')) {
      return AuthException(
        'Kata sandi minimal ${AppConstants.minPasswordLength} karakter.',
      );
    }
    return AuthException(e.message);
  }
}
