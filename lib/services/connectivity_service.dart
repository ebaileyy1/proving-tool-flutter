import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:proving_tool/config.dart';

/// Tracks real internet reachability, not just interface state.
///
/// `connectivity_plus` only reports whether a network interface is up (e.g.
/// connected to Wi-Fi with no upstream internet still reads as "connected"),
/// so every interface change is followed by a short DNS lookup against the
/// Supabase host before [isOnline] flips. A slow periodic re-check covers
/// the case where connectivity changes without an interface event (e.g. a
/// captive portal or an ISP outage).
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  /// True once a real reachability probe has succeeded. Starts optimistic
  /// (true) so the very first frame doesn't flash an offline banner before
  /// the first probe completes.
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _pollTimer;
  bool _started = false;

  static const _probeTimeout = Duration(seconds: 3);
  static const _pollInterval = Duration(seconds: 30);

  void start() {
    if (_started) return;
    _started = true;

    unawaited(checkNow());

    _subscription =
        Connectivity().onConnectivityChanged.listen((_) => checkNow());
    _pollTimer = Timer.periodic(_pollInterval, (_) => checkNow());
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _started = false;
  }

  /// Forces an immediate reachability check and updates [isOnline].
  /// Safe to call anytime, e.g. right before a manual "Sync now" attempt.
  Future<bool> checkNow() async {
    final reachable = await _probe();
    isOnline.value = reachable;
    return reachable;
  }

  Future<bool> _probe() async {
    try {
      final result = await InternetAddress.lookup(
        SupabaseConfig.host,
      ).timeout(_probeTimeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
