/// Domain `UserEntity` — immutable user/profile representation surfaced
/// to use cases and presentation. Mirrors the `profiles` row joined
/// with `auth.users.email`. The role drives all RBAC decisions in the
/// app (ticket visibility, dashboard mode, FAB visibility).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

/// Application role.
///
/// Order matches DB check constraint and `AppConstants.userRoles`.
enum UserRole {
  user,
  helpdesk,
  admin;

  /// Parse the DB string. Defaults to [UserRole.user] for unknown values
  /// so that a corrupt row never crashes the UI.
  static UserRole fromString(String? value) {
    return switch (value) {
      'helpdesk' => UserRole.helpdesk,
      'admin' => UserRole.admin,
      _ => UserRole.user,
    };
  }

  /// Wire value (must round-trip through DB).
  String get wire => name;

  bool get isUser => this == UserRole.user;
  bool get isHelpdesk => this == UserRole.helpdesk;
  bool get isAdmin => this == UserRole.admin;

  /// Helpdesk + Admin can see/manage every ticket.
  bool get canManageAllTickets => isHelpdesk || isAdmin;
}

@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String email,
    required String username,
    required String fullName,
    required UserRole role,
    String? avatarUrl,
    required DateTime createdAt,
  }) = _UserEntity;
}
