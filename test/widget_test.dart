// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/main.dart'; // Update if your app file is named differently

void main() {
  testWidgets('InvoiceEasy Home screen UI test', (WidgetTester tester) async {
    // Build the InvoiceEasy app
    await tester.pumpWidget(const InvoiceApp());

    // Verify the title is shown
    expect(find.text('InvoiceEasy'), findsWidgets);

    // Verify home screen action buttons are present
    expect(find.text('View Invoices'), findsOneWidget);
    expect(find.text('New Invoice'), findsOneWidget);

    // Tap the 'View Invoices' button and ensure navigation works
    await tester.tap(find.text('View Invoices'));
    await tester.pumpAndSettle();

    // Optionally check for expected content on InvoiceListScreen
    // e.g., expect(find.text('No invoices yet'), findsOneWidget);

    // Return to home screen
    tester.pageBack(); // Simulates back navigation
    await tester.pumpAndSettle();

    // Tap the 'New Invoice' button and check navigation
    await tester.tap(find.text('New Invoice'));
    await tester.pumpAndSettle();

    // Check if form fields are visible
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Qty'), findsOneWidget);
    expect(find.text('Price'), findsOneWidget);
  });
}
