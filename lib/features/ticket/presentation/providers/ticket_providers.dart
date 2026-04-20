/// Shared Riverpod providers for the ticket feature — datasource,
/// repository, and use cases. The list/detail state providers live in
/// their own files and `ref.watch` these.
///
/// Generated file: `ticket_providers.g.dart`.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../../domain/usecases/add_comment_usecase.dart';
import '../../domain/usecases/assign_ticket_usecase.dart';
import '../../domain/usecases/create_ticket_usecase.dart';
import '../../domain/usecases/get_ticket_detail_usecase.dart';
import '../../domain/usecases/get_tickets_usecase.dart';
import '../../domain/usecases/update_ticket_status_usecase.dart';

part 'ticket_providers.g.dart';

@Riverpod(keepAlive: true)
TicketRemoteDataSource ticketRemoteDataSource(
  TicketRemoteDataSourceRef ref,
) =>
    TicketRemoteDataSource(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
TicketRepository ticketRepository(TicketRepositoryRef ref) =>
    TicketRepositoryImpl(ref.watch(ticketRemoteDataSourceProvider));

@riverpod
GetTicketsUseCase getTicketsUseCase(GetTicketsUseCaseRef ref) =>
    GetTicketsUseCase(ref.watch(ticketRepositoryProvider));

@riverpod
GetTicketDetailUseCase getTicketDetailUseCase(
  GetTicketDetailUseCaseRef ref,
) =>
    GetTicketDetailUseCase(ref.watch(ticketRepositoryProvider));

@riverpod
CreateTicketUseCase createTicketUseCase(CreateTicketUseCaseRef ref) =>
    CreateTicketUseCase(ref.watch(ticketRepositoryProvider));

@riverpod
UpdateTicketStatusUseCase updateTicketStatusUseCase(
  UpdateTicketStatusUseCaseRef ref,
) =>
    UpdateTicketStatusUseCase(ref.watch(ticketRepositoryProvider));

@riverpod
AssignTicketUseCase assignTicketUseCase(AssignTicketUseCaseRef ref) =>
    AssignTicketUseCase(ref.watch(ticketRepositoryProvider));

@riverpod
AddCommentUseCase addCommentUseCase(AddCommentUseCaseRef ref) =>
    AddCommentUseCase(ref.watch(ticketRepositoryProvider));
