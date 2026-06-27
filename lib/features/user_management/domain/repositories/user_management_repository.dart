/// Abstract contract for admin user management (FR-007.7 + BR-002.9).
///
/// All methods return `Either<Failure, T>`. The data layer enforces
/// nothing role-wise itself — the Supabase RLS policy
/// `profiles_admin_update` (migration 002) is the real gate; these
/// methods simply fail with a [PermissionFailure] if a non-admin calls
/// a mutation.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';

abstract class UserManagementRepository {
  /// All profiles, newest first. Optional [search] filters by full name
  /// or username (case-insensitive).
  Future<Either<Failure, List<UserEntity>>> getUsers({String? search});

  /// Change a user's [role] (`user` | `helpdesk` | `admin`).
  Future<Either<Failure, UserEntity>> updateRole({
    required String userId,
    required UserRole role,
  });

  /// Activate / deactivate an account. Deactivated users are blocked at
  /// login and cannot create tickets.
  Future<Either<Failure, UserEntity>> setActive({
    required String userId,
    required bool isActive,
  });
}
