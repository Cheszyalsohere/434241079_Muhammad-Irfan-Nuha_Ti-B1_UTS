/// Thin wrapper around `connectivity_plus` that exposes a simple
/// `bool` (online / offline) stream + a synchronous getter.
///
/// Anything that returns a non-`none` connectivity result is treated
/// as "online" — we don't try to ping the internet here. Higher
/// layers (e.g. provider error handling) decide what to do when an
/// actual request fails despite the radio being on.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  bool _lastKnown = true;

  bool get isOnline => _lastKnown;

  /// Emits `true` (online) / `false` (offline) on every change.
  ///
  /// Seeds with the current snapshot so subscribers don't have to
  /// poll separately on first build.
  Stream<bool> get onStatusChange async* {
    final List<ConnectivityResult> initial =
        await _connectivity.checkConnectivity();
    _lastKnown = _isOnlineFrom(initial);
    yield _lastKnown;

    yield* _connectivity.onConnectivityChanged.map(
      (List<ConnectivityResult> results) {
        _lastKnown = _isOnlineFrom(results);
        return _lastKnown;
      },
    );
  }

  /// One-shot snapshot, useful for "guard before fetch" checks.
  Future<bool> check() async {
    final List<ConnectivityResult> results =
        await _connectivity.checkConnectivity();
    _lastKnown = _isOnlineFrom(results);
    return _lastKnown;
  }

  bool _isOnlineFrom(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((ConnectivityResult r) => r != ConnectivityResult.none);
  }
}
