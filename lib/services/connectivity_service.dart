import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:proving_tool/config.dart';

/// Tracks real reachability. connectivity_plus only reports interface state,
/// so changes are confirmed with a DNS lookup on the Supabase host, and a
/// slow poll catches things like captive portals.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  /// Starts true so the first frame doesn't flash an offline banner.
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

    _subscription = Connectivity().onConnectivityChanged.listen((_) => checkNow());
    _pollTimer = Timer.periodic(_pollInterval, (_) => checkNow());
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _started = false;
  }

  /// Probes now and updates [isOnline].
  Future<bool> checkNow() async {
    final reachable = await _probe();
    isOnline.value = reachable;
    return reachable;
  }

  Future<bool> _probe() async {
    try {
      final result = await InternetAddress.lookup(SupabaseConfig.host).timeout(_probeTimeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
