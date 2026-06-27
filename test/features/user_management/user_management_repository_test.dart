// Unit tests for UserManagementRepositoryImpl.
//
// Uses a manual fake datasource (the project has no mockito), per the
// flutter-testing skill's manual-mocking pattern. Verifies the happy
// path and the exception -> Failure mapping that the presentation layer
// relies on.

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_ticketing_helpdesk/core/errors/exceptions.dart';
import 'package:e_ticketing_helpdesk/core/errors/failures.dart';
import 'package:e_ticketing_helpdesk/features/auth/data/models/user_model.dart';
import 'package:e_ticketing_helpdesk/features/auth/domain/entities/user_entity.dart';
import 'package:e_ticketing_helpdesk/features/user_management/data/datasources/user_management_remote_datasource.dart';
import 'package:e_ticketing_helpdesk/features/user_management/data/repositories/user_management_repository_impl.dart';

UserModel _sample({
  String id = '1',
  String role = 'user',
  bool isActive = true,
}) =>
    UserModel(
      id: id,
      username: 'user$id',
      fullName: 'User $id',
      role: role,
      createdAt: DateTime(2026, 1, 1),
      isActive: isActive,
    );

/// Manual fake — implements the public datasource contract; private
/// members of the concrete class aren't required across libraries.
class _FakeDataSource implements UserManagementRemoteDataSource {
  _FakeDataSource({this.users = const <UserModel>[], this.error});

  List<UserModel> users;
  Object? error;

  String? lastSearch;
  String? lastRoleUserId;
  String? lastRole;
  String? lastActiveUserId;
  bool? lastActive;

  @override
  Future<List<UserModel>> getUsers({String? search}) async {
    if (error != null) throw error!;
    lastSearch = search;
    return users;
  }

  @override
  Future<UserModel> updateRole({
    required String userId,
    required String role,
  }) async {
    if (error != null) throw error!;
    lastRoleUserId = userId;
    lastRole = role;
    return users.firstWhere((UserModel u) => u.id == userId).copyWith(role: role);
  }

  @override
  Future<UserModel> setActive({
    required String userId,
    required bool isActive,
  }) async {
    if (error != null) throw error!;
    lastActiveUserId = userId;
    lastActive = isActive;
    return users
        .firstWhere((UserModel u) => u.id == userId)
        .copyWith(isActive: isActive);
  }
}

void main() {
  group('UserManagementRepositoryImpl.getUsers', () {
    test('returns mapped entities on success', () async {
      final fake = _FakeDataSource(users: <UserModel>[
        _sample(id: '1', role: 'admin'),
        _sample(id: '2', role: 'user', isActive: false),
      ]);
      final repo = UserManagementRepositoryImpl(fake);

      final Either<Failure, List<UserEntity>> result =
          await repo.getUsers(search: 'foo');

      final List<UserEntity> users =
          result.getOrElse(() => <UserEntity>[]);
      expect(users, hasLength(2));
      expect(users[0].role, UserRole.admin);
      expect(users[1].isActive, isFalse);
      expect(fake.lastSearch, 'foo');
    });

    test('maps a generic ServerException to ServerFailure', () async {
      final fake = _FakeDataSource(error: const ServerException('boom'));
      final repo = UserManagementRepositoryImpl(fake);

      final Either<Failure, List<UserEntity>> result = await repo.getUsers();

      final Failure f = result.fold((Failure f) => f, (_) => const UnknownFailure());
      expect(f, isA<ServerFailure>());
    });

    test('maps a permission message to PermissionFailure', () async {
      final fake = _FakeDataSource(
        error: const ServerException('Anda tidak memiliki izin untuk tindakan ini.'),
      );
      final repo = UserManagementRepositoryImpl(fake);

      final Either<Failure, List<UserEntity>> result = await repo.getUsers();

      final Failure f = result.fold((Failure f) => f, (_) => const UnknownFailure());
      expect(f, isA<PermissionFailure>());
    });
  });

  group('UserManagementRepositoryImpl mutations', () {
    test('updateRole forwards the wire role and returns the updated user',
        () async {
      final fake = _FakeDataSource(users: <UserModel>[_sample(id: '7')]);
      final repo = UserManagementRepositoryImpl(fake);

      final Either<Failure, UserEntity> result =
          await repo.updateRole(userId: '7', role: UserRole.helpdesk);

      expect(fake.lastRole, 'helpdesk');
      expect(fake.lastRoleUserId, '7');
      final UserEntity u = result.getOrElse(() => throw StateError('left'));
      expect(u.role, UserRole.helpdesk);
    });

    test('setActive forwards the flag and returns the updated user', () async {
      final fake = _FakeDataSource(users: <UserModel>[_sample(id: '9')]);
      final repo = UserManagementRepositoryImpl(fake);

      final Either<Failure, UserEntity> result =
          await repo.setActive(userId: '9', isActive: false);

      expect(fake.lastActive, isFalse);
      expect(fake.lastActiveUserId, '9');
      final UserEntity u = result.getOrElse(() => throw StateError('left'));
      expect(u.isActive, isFalse);
    });
  });
}
