import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_easy/models/business_profile.dart';
import 'package:invoice_easy/models/customer.dart';
import 'package:invoice_easy/models/invoice.dart';
import 'package:invoice_easy/models/product.dart';

void main() {
  test('business profile round-trips through JSON', () {
    final original = BusinessProfile(
      id: 'b1',
      name: 'Acme Ltd',
      businessType: 'Retail',
      currency: 'KES',
      vatRegistered: true,
      vatRate: 16,
      nextInvoiceNumber: 42,
      updatedAt: DateTime.utc(2026, 10, 1, 10, 30),
    );

    final restored = BusinessProfile.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.businessType, original.businessType);
    expect(restored.vatRegistered, isTrue);
    expect(restored.vatRate, 16);
    expect(restored.nextInvoiceNumber, 42);
    expect(restored.updatedAt, original.updatedAt);
  });

  test('customer round-trips through JSON', () {
    final original = Customer(
      id: 'c1',
      name: 'Jane Doe',
      phone: '0712345678',
      email: 'jane@example.test',
      taxId: 'P051234567A',
      updatedAt: DateTime.utc(2026, 10, 2),
    );

    final restored = Customer.fromJson(original.toJson());

    expect(restored.toJson(), original.toJson());
  });

  test('product round-trips enum, numeric and boolean fields', () {
    final original = ProductItem(
      id: 'p1',
      name: 'Consulting',
      type: ProductType.service,
      price: 12500.50,
      unit: 'hour',
      taxable: true,
      updatedAt: DateTime.utc(2026, 10, 3),
    );

    final restored = ProductItem.fromJson(original.toJson());

    expect(restored.toJson(), original.toJson());
    expect(restored.type, ProductType.service);
    expect(restored.price, 12500.50);
    expect(restored.taxable, isTrue);
  });

  test('invoice round-trips lines, payments and enums', () {
    final original = Invoice(
      id: 'i1',
      businessId: 'b1',
      customerId: 'c1',
      customerName: 'Jane Doe',
      number: 'INV-0042',
      issueDate: DateTime.utc(2026, 10, 4),
      dueDate: DateTime.utc(2026, 10, 18),
      lines: const [
        InvoiceLine(
          id: 'l1',
          description: 'Consulting',
          quantity: 2,
          unitPrice: 5000,
          taxable: true,
        ),
      ],
      status: InvoiceStatus.partiallyPaid,
      discount: 500,
      vatEnabled: true,
      vatRate: 16,
      payments: [
        Payment(
          id: 'p1',
          date: DateTime.utc(2026, 10, 5),
          amount: 3000,
          method: PaymentMethod.mpesa,
          reference: 'ABC123',
        ),
      ],
      notes: 'Thank you',
      archived: true,
      updatedAt: DateTime.utc(2026, 10, 5),
    );

    final restored = Invoice.fromJson(original.toJson());

    expect(restored.toJson(), original.toJson());
    expect(restored.lines.single.total, 10000);
    expect(restored.payments.single.method, PaymentMethod.mpesa);
    expect(restored.status, InvoiceStatus.partiallyPaid);
  });

  test('unknown enum values safely fall back', () {
    final product = ProductItem.fromJson({
      'id': 'p1',
      'name': 'Legacy',
      'type': 'removed_type',
      'price': 100,
    });
    final invoice = Invoice.fromJson({
      'id': 'i1',
      'customerId': 'c1',
      'lines': [
        {'id': 'l1', 'description': 'Item', 'quantity': 1, 'unitPrice': 10},
      ],
      'status': 'removed_status',
      'payments': [
        {'id': 'p1', 'date': '2026-10-01T00:00:00Z', 'amount': 10, 'method': 'removed_method'},
      ],
    });

    expect(product.type, ProductType.service);
    expect(invoice.status, InvoiceStatus.draft);
    expect(invoice.payments.single.method, PaymentMethod.other);
  });
}
