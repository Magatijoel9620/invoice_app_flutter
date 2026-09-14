import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_easy/models/invoice.dart';
import 'package:invoice_easy/core/invoice_status.dart';

void main() {
  Invoice makeInvoice({bool vat = true, List<Payment> payments = const [], InvoiceStatus status = InvoiceStatus.sent, DateTime? due}) => Invoice(
        id: '1',
        businessId: 'default',
        customerId: 'c1',
        customerName: 'Customer',
        number: 'INV-0001',
        issueDate: DateTime(2026, 9, 1),
        dueDate: due ?? DateTime(2026, 9, 30),
        lines: const [InvoiceLine(id: 'l1', description: 'Service', quantity: 1, unitPrice: 1000, taxable: true)],
        status: status,
        vatEnabled: vat,
        vatRate: 16,
        payments: payments,
      );

  test('invoice totals include VAT only when enabled', () {
    expect(makeInvoice().total(16), 1160);
    expect(makeInvoice(vat: false).total(16), 1000);
  });

  test('payment balance and paid status are calculated correctly', () {
    final invoice = makeInvoice(payments: [Payment(id: 'p1', date: DateTime(2026, 9, 2), amount: 1160, method: PaymentMethod.mpesa)]);
    expect(invoice.amountPaid, 1160);
    expect(invoice.balance(invoice.vatRate), 0);
    expect(effectiveInvoiceStatus(invoice, invoice.vatRate), InvoiceStatus.paid);
  });
}
