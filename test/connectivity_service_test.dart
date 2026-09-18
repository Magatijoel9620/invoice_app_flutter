import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:invoice_easy/services/connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reports online only when transport and internet probe both succeed', () async {
    final service = ConnectivityService(
      checkConnectivity: () async => [ConnectivityResult.wifi],
      reachabilityProbe: () async => true,
    );

    await service.check();

    expect(service.state, ConnectivityState.online);
    expect(service.isOnline, isTrue);
  });

  test('reports offline when there is no network transport', () async {
    final service = ConnectivityService(
      checkConnectivity: () async => [ConnectivityResult.none],
      reachabilityProbe: () async => true,
    );

    await service.check();

    expect(service.state, ConnectivityState.offline);
  });

  test('reports offline when transport exists but internet is unreachable', () async {
    final service = ConnectivityService(
      checkConnectivity: () async => [ConnectivityResult.mobile],
      reachabilityProbe: () async => false,
    );

    await service.check();

    expect(service.state, ConnectivityState.offline);
  });
}

// Startup behaviour is exercised by the app widget test; this test verifies
// the service can be checked before any authenticated session exists.
