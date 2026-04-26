/// Use case: subscribe to the realtime notification stream.
///
/// Returns a `Stream<List<NotificationEntity>>` that emits the full
/// current list every time anything changes — see
/// [NotificationRepository.subscribeToNotifications].
library;

import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class SubscribeNotificationsUseCase {
  const SubscribeNotificationsUseCase(this._repo);

  final NotificationRepository _repo;

  Stream<List<NotificationEntity>> call({required String userId}) =>
      _repo.subscribeToNotifications(userId);
}
