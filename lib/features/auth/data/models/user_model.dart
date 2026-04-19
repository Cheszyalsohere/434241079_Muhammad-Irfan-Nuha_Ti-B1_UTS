/// Freezed `UserModel` with JSON (de)serialization for `profiles` rows.
///
/// The Supabase `profiles` table only stores: id, username, full_name,
/// role, avatar_url, created_at. The user's `email` lives on
/// `auth.users` and is injected by the repository when constructing the
/// model. We accept it as a regular optional field here so the same
/// `fromJson`/`toEntity` path works for both:
///   • profile-only payloads from `from('profiles').select()`
///   • augmented maps that the repository assembles
///     `{ ...profileRow, 'email': session.user.email }`
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    required String username,
    @JsonKey(name: 'full_name') required String fullName,
    required String role,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    String? email,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Map the wire row to a domain entity. Falls back to an empty string
  /// when the email is not yet populated — the repository always
  /// supplies it for live sessions.
  UserEntity toEntity() => UserEntity(
        id: id,
        email: email ?? '',
        username: username,
        fullName: fullName,
        role: UserRole.fromString(role),
        avatarUrl: avatarUrl,
        createdAt: createdAt,
      );
}
