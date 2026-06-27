// Unit tests for UserModel <-> UserEntity mapping, focused on the
// `is_active` field added for user management (migration 002).

import 'package:flutter_test/flutter_test.dart';

import 'package:e_ticketing_helpdesk/features/auth/data/models/user_model.dart';
import 'package:e_ticketing_helpdesk/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserModel.is_active mapping', () {
    test('parses is_active=false from JSON and carries it to the entity', () {
      final UserModel model = UserModel.fromJson(<String, dynamic>{
        'id': 'abc',
        'username': 'jane',
        'full_name': 'Jane Doe',
        'role': 'helpdesk',
        'created_at': '2026-01-01T00:00:00Z',
        'is_active': false,
      });

      expect(model.isActive, isFalse);
      expect(model.toEntity().isActive, isFalse);
      expect(model.toEntity().role, UserRole.helpdesk);
    });

    test('defaults to active when the is_active key is absent', () {
      final UserModel model = UserModel.fromJson(<String, dynamic>{
        'id': 'abc',
        'username': 'jane',
        'full_name': 'Jane Doe',
        'role': 'user',
        'created_at': '2026-01-01T00:00:00Z',
      });

      expect(model.isActive, isTrue);
      expect(model.toEntity().isActive, isTrue);
    });
  });
}
