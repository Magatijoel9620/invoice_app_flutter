import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_easy/core/invoice_status.dart';
import 'package:invoice_easy/models/invoice.dart';

Invoice invoice({
  InvoiceStatus status = InvoiceStatus.sent,
  double paid = 0,
  DateTime? dueDate,
}) => Invoice(
  id: 'i1',
  businessId: 'b1',
  customerId: 'c1',
  customerName: 'Customer',
  number: 'INV-1',
  issueDate: DateTime(2026, 10, 1),
  dueDate: dueDate ?? DateTime(2026, 10, 31),
  lines: const [
    InvoiceLine(
      id: 'l1',
      description: 'Service',
      quantity: 1,
      unitPrice: 1000,
      taxable: true,
    ),
  ],
  status: status,
  vatEnabled: true,
  vatRate: 16,
  payments: paid == 0
      ? const []
      : [
          Payment(
            id: 'p1',
            date: DateTime(2026, 10, 2),
            amount: paid,
            method: PaymentMethod.cash,
          ),
        ],
);

void main() {
  final now = DateTime(2026, 10, 15);

  test('preserves cancelled and draft states', () {
    expect(
      effectiveInvoiceStatus(invoice(status: InvoiceStatus.cancelled), 16, now: now),
      InvoiceStatus.cancelled,
    );
    expect(
      effectiveInvoiceStatus(invoice(status: InvoiceStatus.draft), 16, now: now),
      InvoiceStatus.draft,
    );
  });

  test('detects partial payment before overdue state', () {
    final value = invoice(
      paid: 100,
      dueDate: DateTime(2026, 10, 10),
    );
    expect(effectiveInvoiceStatus(value, 16, now: now), InvoiceStatus.partiallyPaid);
  });

  test('detects overdue unpaid invoice', () {
    final value = invoice(dueDate: DateTime(2026, 10, 10));
    expect(effectiveInvoiceStatus(value, 16, now: now), InvoiceStatus.overdue);
  });

  test('keeps viewed state when still unpaid and not overdue', () {
    final value = invoice(status: InvoiceStatus.viewed);
    expect(effectiveInvoiceStatus(value, 16, now: now), InvoiceStatus.viewed);
  });

  test('fully paid invoice wins over original status', () {
    final value = invoice(paid: 1160, dueDate: DateTime(2026, 10, 10));
    expect(effectiveInvoiceStatus(value, 16, now: now), InvoiceStatus.paid);
  });
}
