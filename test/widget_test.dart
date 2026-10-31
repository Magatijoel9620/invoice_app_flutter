import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:invoice_easy/main.dart';
import 'package:invoice_easy/services/local_store.dart';
import 'package:invoice_easy/services/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:invoice_easy/providers/app_providers.dart';
import 'package:invoice_easy/screens/create_invoice_screen.dart';
import 'package:invoice_easy/screens/widgets/skeleton_loader.dart';

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

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Dashboard'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Invoices'));
    await tester.pumpAndSettle();

    expect(find.text('Invoices'), findsWidgets);
    expect(
      find.text('Search, filter and manage every invoice.'),
      findsOneWidget,
    );
  });

  testWidgets('shows all dashboard stats on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    expect(find.text('Invoiced'), findsWidgets);
    expect(find.text('Collected'), findsWidgets);
    expect(find.text('Outstanding'), findsWidgets);
    expect(find.text('Overdue'), findsWidgets);
    final invoicedCard = find
        .ancestor(
          of: find.text('Invoiced').first,
          matching: find.byType(Card),
        )
        .first;
    final collectedCard = find
        .ancestor(
          of: find.text('Collected').first,
          matching: find.byType(Card),
        )
        .first;
    expect(
      tester.getSize(invoicedCard).width,
      greaterThan(tester.getSize(collectedCard).width * 1.8),
      reason: 'The mobile dashboard should use a featured Bento KPI.',
    );
    final exception = tester.takeException();
    expect(exception, isNull, reason: '$exception');
  });

  testWidgets('create invoice form stays usable across viewport sizes', (
    tester,
  ) async {
    for (final width in [320.0, 360.0, 600.0, 760.0, 1024.0]) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey(width),
          child: const MaterialApp(home: CreateInvoiceScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(tester.getSize(find.byType(ListView)).height, greaterThan(0));
      expect(find.text('Invoice details'), findsOneWidget);
      expect(find.text('Items'), findsOneWidget);
      expect(find.text('Save draft'), findsOneWidget);
      expect(find.text('Create & send'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Notes'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Notes'), findsOneWidget);
      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason: 'Create invoice overflowed at $width px: $exception',
      );
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('loading skeletons fit phone, tablet and desktop widths', (
    tester,
  ) async {
    for (final width in [320.0, 360.0, 600.0, 760.0, 1024.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      for (final loader in <Widget>[
        const DashboardLoadingState(),
        const RecordListLoadingState(
          rows: 3,
          showSearch: true,
          showFilters: true,
        ),
        const ReportsLoadingState(),
        const PlanLoadingState(),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: loader,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 80));
        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason: 'Loader ${loader.runtimeType} overflowed at $width px: $exception',
        );
      }
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('main shell stays usable across responsive breakpoints', (
    tester,
  ) async {
    final connectivity = ConnectivityService(
      checkConnectivity: () async => [ConnectivityResult.wifi],
      reachabilityProbe: () async => true,
    );
    connectivity.state = ConnectivityState.online;

    for (final width in [320.0, 360.0, 600.0, 760.0, 1024.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityProvider.overrideWith((ref) => connectivity),
          ],
          child: InvoiceEasyApp(key: ValueKey(width)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Dashboard overflowed at $width px',
      );

      Finder navigationLabel(String destination) {
        if (width < 760) {
          final label = destination == 'Dashboard' ? 'Home' : destination;
          return find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          );
        }
        if (width < 1180) {
          return find.descendant(
            of: find.byType(NavigationRail),
            matching: find.text(destination),
          );
        }
        return find.text(destination).last;
      }

      final destinations = width >= 1180
          ? ['Invoices', 'Customers', 'Products & Services']
          : ['Invoices', 'Customers', 'Catalog'];
      for (final destination in destinations) {
        final target = navigationLabel(destination);
        expect(
          target,
          findsOneWidget,
          reason: '$destination missing at $width px',
        );
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '$destination overflowed at $width px',
        );
      }

      await tester.tap(navigationLabel('Dashboard'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Reports'));
      await tester.pumpAndSettle();
      expect(find.text('Reports & analytics'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Reports overflowed at $width px',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archived invoices').last);
      await tester.pumpAndSettle();
      expect(find.text('Archived invoices'), findsWidgets);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Archive overflowed at $width px',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Business settings').last);
      await tester.pumpAndSettle();
      expect(find.text('Business identity'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Business settings overflowed at $width px',
      );
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

}
