// Unit tests for the admin per-helpdesk filter (FR-007.3): verify that
// TicketRepositoryImpl forwards the `assignedTo` argument (including the
// unassigned sentinel) down to the datasource's listTickets call.

import 'package:flutter_test/flutter_test.dart';

import 'package:e_ticketing_helpdesk/features/ticket/data/datasources/ticket_remote_datasource.dart';
import 'package:e_ticketing_helpdesk/features/ticket/data/models/ticket_model.dart';
import 'package:e_ticketing_helpdesk/features/ticket/data/repositories/ticket_repository_impl.dart';
import 'package:e_ticketing_helpdesk/features/ticket/domain/entities/ticket_entity.dart';
import 'package:e_ticketing_helpdesk/features/ticket/domain/repositories/ticket_repository.dart';

class _FakeTicketDs implements TicketRemoteDataSource {
  String? capturedAssignedTo;
  bool listCalled = false;

  @override
  Future<List<TicketModel>> listTickets({
    required int page,
    required int pageSize,
    TicketScope scope = TicketScope.all,
    TicketStatus? status,
    String? search,
    String? assignedTo,
  }) async {
    listCalled = true;
    capturedAssignedTo = assignedTo;
    return const <TicketModel>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not needed for this test');
}

void main() {
  group('TicketRepositoryImpl.getTickets assignee filter', () {
    test('forwards a specific helpdesk id to the datasource', () async {
      final fake = _FakeTicketDs();
      final repo = TicketRepositoryImpl(fake);

      await repo.getTickets(page: 0, pageSize: 20, assignedTo: 'helpdesk-1');

      expect(fake.listCalled, isTrue);
      expect(fake.capturedAssignedTo, 'helpdesk-1');
    });

    test('forwards the unassigned sentinel', () async {
      final fake = _FakeTicketDs();
      final repo = TicketRepositoryImpl(fake);

      await repo.getTickets(
        page: 0,
        pageSize: 20,
        assignedTo: kUnassignedTicketsFilter,
      );

      expect(fake.capturedAssignedTo, kUnassignedTicketsFilter);
    });

    test('passes null when no filter is set', () async {
      final fake = _FakeTicketDs();
      final repo = TicketRepositoryImpl(fake);

      await repo.getTickets(page: 0, pageSize: 20);

      expect(fake.capturedAssignedTo, isNull);
    });
  });
}
