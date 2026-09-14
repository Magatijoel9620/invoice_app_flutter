import '../models/invoice.dart';

InvoiceStatus effectiveInvoiceStatus(Invoice invoice, double vatRate, {DateTime? now}) {
  if (invoice.status == InvoiceStatus.cancelled) return InvoiceStatus.cancelled;
  if (invoice.status == InvoiceStatus.draft) return InvoiceStatus.draft;

  // The VAT rate belongs to the invoice. The business default may have changed since it was issued.
  final balance = invoice.balance(invoice.vatRate);
  if (balance <= 0.009) return InvoiceStatus.paid;
  if (invoice.amountPaid > 0) return InvoiceStatus.partiallyPaid;
  final current = now ?? DateTime.now();
  if (invoice.dueDate.isBefore(DateTime(current.year, current.month, current.day))) {
    return InvoiceStatus.overdue;
  }
  return invoice.status == InvoiceStatus.viewed ? InvoiceStatus.viewed : InvoiceStatus.sent;
}

String invoiceStatusLabel(InvoiceStatus status) => switch (status) {
      InvoiceStatus.partiallyPaid => 'Partial',
      InvoiceStatus.draft => 'Draft',
      InvoiceStatus.sent => 'Sent',
      InvoiceStatus.viewed => 'Viewed',
      InvoiceStatus.paid => 'Paid',
      InvoiceStatus.overdue => 'Overdue',
      InvoiceStatus.cancelled => 'Cancelled',
    };
