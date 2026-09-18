import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'cloud_config.dart';

/// The transport-independent state used by the app UX.
enum ConnectivityState { checking, online, offline }

/// Detects both network transport and actual internet reachability.
///
/// connectivity_plus tells us whether a network interface exists; it does
/// not guarantee that the internet is reachable. We therefore follow a
/// transport change with a lightweight HTTP probe.
class ConnectivityService extends ChangeNotifier with WidgetsBindingObserver {
  ConnectivityService({
    Connectivity? connectivity,
    Stream<List<ConnectivityResult>>? connectivityChanges,
    Future<List<ConnectivityResult>> Function()? checkConnectivity,
    Future<bool> Function()? reachabilityProbe,
  })  : _connectivity = connectivity ?? Connectivity(),
        _connectivityChanges = connectivityChanges,
        _checkConnectivity = checkConnectivity,
        _reachabilityProbe = reachabilityProbe;

  final Connectivity _connectivity;
  final Stream<List<ConnectivityResult>>? _connectivityChanges;
  final Future<List<ConnectivityResult>> Function()? _checkConnectivity;
  final Future<bool> Function()? _reachabilityProbe;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _pollTimer;
  bool _started = false;
  bool _checking = false;

  ConnectivityState state = ConnectivityState.checking;
  List<ConnectivityResult> transports = const [];
  DateTime? lastCheckedAt;

  bool get isOnline => state == ConnectivityState.online;
  bool get isOffline => state == ConnectivityState.offline;
  bool get isChecking => state == ConnectivityState.checking;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);

    _subscription = (_connectivityChanges ?? _connectivity.onConnectivityChanged)
        .listen((results) {
      transports = List.unmodifiable(results);
      unawaited(check());
    });

    // A periodic check catches captive portals and networks that silently lose
    // internet access without changing their transport type.
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused &&
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.detached) {
        unawaited(check());
      }
    });

    await check();
  }

  Future<void> check() async {
    if (_checking) return;
    _checking = true;
    final previous = state;
    state = ConnectivityState.checking;
    notifyListeners();

    try {
      final results = await (_checkConnectivity?.call() ??
          _connectivity.checkConnectivity());
      transports = List.unmodifiable(results);

      if (results.every((item) => item == ConnectivityResult.none)) {
        _setState(ConnectivityState.offline);
      } else {
        final reachable = await (_reachabilityProbe?.call() ?? _probeInternet());
        _setState(reachable ? ConnectivityState.online : ConnectivityState.offline);
      }
      lastCheckedAt = DateTime.now().toUtc();
      notifyListeners();
    } catch (_) {
      _setState(ConnectivityState.offline);
      lastCheckedAt = DateTime.now().toUtc();
      notifyListeners();
    } finally {
      _checking = false;
    }

    // State transitions are observable through ChangeNotifier. Keeping the
    // previous value here also makes debugging transition behaviour easier.
    if (previous != state) notifyListeners();
  }

  Future<bool> _probeInternet() async {
    final uri = CloudConfig.isConfigured
        ? Uri.parse('${CloudConfig.url.replaceAll(RegExp(r'/+$'), '')}/auth/v1/health')
        : Uri.parse('https://www.google.com/generate_204');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      // Any HTTP response means the network path is reachable. Authentication
      // or API errors are application-level concerns, not connectivity loss.
      return response.statusCode >= 100 && response.statusCode < 600;
    } catch (_) {
      return false;
    }
  }

  void _setState(ConnectivityState value) {
    state = value;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appLifecycleState) {
    if (appLifecycleState == AppLifecycleState.resumed) {
      unawaited(check());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}
