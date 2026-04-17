/// Form validators — return `String?` (null = valid) for direct use in
/// `TextFormField.validator`. All messages are in Indonesian.
library;

import '../config/app_constants.dart';

abstract final class Validators {
  static final RegExp _emailRe = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  static final RegExp _usernameRe = RegExp(r'^[A-Za-z0-9_.]{3,20}$');

  /// Required non-empty field.
  static String? required(String? value, {String field = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field wajib diisi';
    }
    return null;
  }

  /// Valid email format.
  static String? email(String? value) {
    final String? req = required(value, field: 'Email');
    if (req != null) return req;
    if (!_emailRe.hasMatch(value!.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Password minimum length — Supabase default is 6.
  static String? password(String? value) {
    final String? req = required(value, field: 'Kata sandi');
    if (req != null) return req;
    if (value!.length < AppConstants.minPasswordLength) {
      return 'Kata sandi minimal ${AppConstants.minPasswordLength} karakter';
    }
    return null;
  }

  /// Confirmation must match original.
  static String? Function(String?) confirmPassword(String original) {
    return (String? value) {
      final String? req = required(value, field: 'Konfirmasi kata sandi');
      if (req != null) return req;
      if (value != original) {
        return 'Konfirmasi tidak sama dengan kata sandi';
      }
      return null;
    };
  }

  /// Username: 3–20 chars, alphanumeric / dot / underscore.
  static String? username(String? value) {
    final String? req = required(value, field: 'Username');
    if (req != null) return req;
    if (!_usernameRe.hasMatch(value!.trim())) {
      return 'Username 3–20 karakter (huruf, angka, titik, garis bawah)';
    }
    return null;
  }

  /// Ticket title length cap.
  static String? ticketTitle(String? value) {
    final String? req = required(value, field: 'Judul');
    if (req != null) return req;
    if (value!.length > AppConstants.maxTitleLength) {
      return 'Judul maksimal ${AppConstants.maxTitleLength} karakter';
    }
    return null;
  }

  /// Ticket description length cap.
  static String? ticketDescription(String? value) {
    final String? req = required(value, field: 'Deskripsi');
    if (req != null) return req;
    if (value!.length > AppConstants.maxDescriptionLength) {
      return 'Deskripsi maksimal ${AppConstants.maxDescriptionLength} karakter';
    }
    return null;
  }

  /// Comment/reply length cap.
  static String? comment(String? value) {
    final String? req = required(value, field: 'Balasan');
    if (req != null) return req;
    if (value!.length > AppConstants.maxCommentLength) {
      return 'Balasan maksimal ${AppConstants.maxCommentLength} karakter';
    }
    return null;
  }

  /// Full name — just non-empty, trimmed length reasonable.
  static String? fullName(String? value) {
    final String? req = required(value, field: 'Nama lengkap');
    if (req != null) return req;
    if (value!.trim().length < 2) {
      return 'Nama terlalu pendek';
    }
    return null;
  }
}
