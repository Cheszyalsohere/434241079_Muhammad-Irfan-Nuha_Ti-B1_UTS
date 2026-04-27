/// Riverpod entry points for connectivity state.
///
/// `connectivityServiceProvider` is `keepAlive: true` so the
/// `Connectivity` listener survives across navigations.
/// `connectivityStreamProvider` is the canonical stream of online /
/// offline transitions. `isOnlineProvider` is a synchronous boolean
/// snapshot — defaults to `true` while the first event is in flight
/// so the offline banner doesn't flash on cold start.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'connectivity_service.dart';

part 'connectivity_provider.g.dart';

@Riverpod(keepAlive: true)
ConnectivityService connectivityService(Ref ref) {
  return ConnectivityService();
}

@Riverpod(keepAlive: true)
Stream<bool> connectivityStream(Ref ref) {
  final ConnectivityService service = ref.watch(connectivityServiceProvider);
  return service.onStatusChange;
}

@Riverpod(keepAlive: true)
bool isOnline(Ref ref) {
  final AsyncValue<bool> async = ref.watch(connectivityStreamProvider);
  return async.maybeWhen(
    data: (bool online) => online,
    orElse: () => true, // Optimistic default: don't flash banner on boot.
  );
}
