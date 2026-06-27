// Unit tests for TicketRepositoryImpl.deleteTicket (BR-002.8).
//
// Uses a noSuchMethod fake so only deleteTicket needs a body — the rest
// of the large datasource surface is irrelevant to this test.

import 'package:flutter_test/flutter_test.dart';

import 'package:e_ticketing_helpdesk/core/errors/exceptions.dart';
import 'package:e_ticketing_helpdesk/core/errors/failures.dart';
import 'package:e_ticketing_helpdesk/features/ticket/data/datasources/ticket_remote_datasource.dart';
import 'package:e_ticketing_helpdesk/features/ticket/data/repositories/ticket_repository_impl.dart';

class _FakeTicketDs implements TicketRemoteDataSource {
  _FakeTicketDs({this.error});

  Object? error;
  String? deletedId;

  @override
  Future<void> deleteTicket(String ticketId) async {
    deletedId = ticketId;
    if (error != null) throw error!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not needed for this test');
}

void main() {
  group('TicketRepositoryImpl.deleteTicket', () {
    test('returns Right(unit) and forwards the id on success', () async {
      final fake = _FakeTicketDs();
      final repo = TicketRepositoryImpl(fake);

      final res = await repo.deleteTicket('t1');

      expect(res.isRight(), isTrue);
      expect(fake.deletedId, 't1');
    });

    test('maps a permission message to PermissionFailure', () async {
      final fake = _FakeTicketDs(
        error: const ServerException(
          'Anda tidak memiliki izin untuk menghapus tiket ini.',
        ),
      );
      final repo = TicketRepositoryImpl(fake);

      final res = await repo.deleteTicket('t1');

      final Failure f = res.fold((Failure l) => l, (_) => const UnknownFailure());
      expect(f, isA<PermissionFailure>());
    });
  });
}
