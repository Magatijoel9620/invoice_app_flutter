import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:invoice_easy/main.dart';
import 'package:invoice_easy/services/local_store.dart';
import 'package:invoice_easy/services/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:invoice_easy/providers/app_providers.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'ie_local_scope_v1/anonymous/ie_business_profile_v2':
          '{"id":"default","name":"Test Business","businessType":"Other","phone":"","email":"","address":"","kraPin":"","currency":"KES","invoicePrefix":"INV","nextInvoiceNumber":1,"defaultDueDays":14,"vatRegistered":false,"vatRate":16,"logoPath":"","thankYouMessage":"Thank you for your business!","mpesaTill":"","paybill":"","bankName":"","bankAccount":"","updatedAt":"2000-01-01T00:00:00.000"}',
    });
    await LocalStore.initialize();
  });

  testWidgets('shows the dashboard and switches to invoices', (tester) async {
    final connectivity = ConnectivityService(
      checkConnectivity: () async => [ConnectivityResult.wifi],
      reachabilityProbe: () async => true,
    );
    connectivity.state = ConnectivityState.online;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectivityProvider.overrideWith((ref) => connectivity)],
        child: const InvoiceEasyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    await tester.tap(find.text('Invoices'));
    await tester.pumpAndSettle();

    expect(find.text('Invoices'), findsWidgets);
    expect(
      find.text('Search, filter and manage every invoice.'),
      findsOneWidget,
    );
  });
}

