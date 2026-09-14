import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';

import '../core/formatters.dart';
import '../core/invoice_status.dart';
import '../models/business_profile.dart';
import '../models/invoice.dart';
import '../providers/app_providers.dart';
import '../services/pdf_service.dart';
import '../services/share_service.dart';
import 'create_invoice_screen.dart';

class InvoiceDetailsScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailsScreen> createState() =>
      _InvoiceDetailsState();
}

class _InvoiceDetailsState extends ConsumerState<InvoiceDetailsScreen> {
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(invoicesProvider).valueOrNull ?? <Invoice>[];
    final invoice = invoices.where((item) => item.id == widget.invoiceId).firstOrNull;
    final business = ref.watch(businessProvider).valueOrNull;

    if (invoice == null) {
      return const Scaffold(body: Center(child: Text('Invoice not found')));
    }

    final b = business ??
        BusinessProfile(
          id: 'default',
          name: 'My Business',
          businessType: 'Other',
        );
    final status = effectiveInvoiceStatus(invoice, invoice.vatRate);
    final total = invoice.total(invoice.vatRate);
    final balance = invoice.balance(invoice.vatRate);
    final progress = total <= 0
        ? 0.0
        : (invoice.amountPaid / total).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.number),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _action(value, invoice, b),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'sent',
                child: ListTile(
                  leading: Icon(Icons.send_outlined),
                  title: Text('Mark as sent'),
                ),
              ),
              PopupMenuItem(
                value: 'viewed',
                child: ListTile(
                  leading: Icon(Icons.visibility_outlined),
                  title: Text('Mark as viewed'),
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                ),
              ),
              PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  leading: Icon(Icons.copy_outlined),
                  title: Text('Duplicate'),
                ),
              ),
              PopupMenuItem(
                value: 'cancel',
                child: ListTile(
                  leading: Icon(Icons.block_outlined),
                  title: Text('Cancel invoice'),
                ),
              ),
              PopupMenuItem(
                value: 'archive',
                child: ListTile(
                  leading: Icon(Icons.archive_outlined),
                  title: Text('Archive'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
        children: [
          _hero(invoice, status, total, balance, progress),
          const SizedBox(height: 12),
          _section(
            'Invoice',
            Column(
              children: [
                _row('Issue date', shortDate.format(invoice.issueDate)),
                _row('Due date', shortDate.format(invoice.dueDate)),
                _row('Customer', invoice.customerName),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            'Items',
            Column(
              children: [
                for (final line in invoice.lines)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      line.description,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${line.quantity} × ${money.format(line.unitPrice)}${line.taxable ? ' • Taxable' : ''}',
                    ),
                    trailing: Text(
                      money.format(line.total),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            'Totals',
            Column(
              children: [
                _row('Subtotal', money.format(invoice.subtotal)),
                if (invoice.discount > 0)
                  _row('Discount', '− ${money.format(invoice.discount)}'),
                if (invoice.vatEnabled)
                  _row(
                    'VAT (${invoice.vatRate.toStringAsFixed(0)}%)',
                    money.format(invoice.tax(invoice.vatRate)),
                  ),
                const Divider(),
                _row('Total', money.format(total), bold: true),
                _row('Paid', money.format(invoice.amountPaid)),
                _row('Balance', money.format(balance), bold: true),
              ],
            ),
          ),
          if (invoice.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _section('Notes', Text(invoice.notes)),
          ],
          const SizedBox(height: 12),
          _section(
            'Payments',
            Column(
              children: [
                if (invoice.payments.isEmpty)
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.payments_outlined),
                    title: Text('No payments recorded'),
                    subtitle: Text('Record a payment when your customer pays.'),
                  ),
                ...invoice.payments.map(
                  (payment) => _paymentTile(invoice, payment, b),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: balance <= 0.009 ||
                          status == InvoiceStatus.cancelled
                      ? null
                      : () => _recordPayment(invoice),
                  icon: const Icon(Icons.add_card_outlined),
                  label: const Text('Record payment'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => _preview(invoice, b),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('PDF preview'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () => ShareService.shareInvoice(invoice, b),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hero(
    Invoice invoice,
    InvoiceStatus status,
    double total,
    double balance,
    double progress,
  ) {
    final colors = Theme.of(context).colorScheme;
    final paid = status == InvoiceStatus.paid;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withValues(alpha: .78)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  invoice.customerName,
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusChip(status, colors),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            money.format(total),
            style: TextStyle(
              color: colors.onPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            paid ? 'Fully paid' : '${money.format(balance)} outstanding',
            style: TextStyle(
              color: colors.onPrimary.withValues(alpha: .82),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colors.onPrimary.withValues(alpha: .18),
              color: colors.onPrimary,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${(progress * 100).round()}% collected',
            style: TextStyle(
              color: colors.onPrimary.withValues(alpha: .78),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(InvoiceStatus status, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.onPrimary.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        invoiceStatusLabel(status).toUpperCase(),
        style: TextStyle(
          color: colors.onPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentTile(
    Invoice invoice,
    Payment payment,
    BusinessProfile business,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Icon(_paymentIcon(payment.method), size: 19),
      ),
      title: Text(
        money.format(payment.amount),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${shortDate.format(payment.date)} • ${payment.method.name.toUpperCase()}${payment.reference.isEmpty ? '' : ' • ${payment.reference}'}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) =>
            _paymentAction(value, invoice, payment, business),
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'receipt',
            child: Text('Generate receipt'),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Text('Delete payment'),
          ),
        ],
      ),
    );
  }

  IconData _paymentIcon(PaymentMethod method) => switch (method) {
        PaymentMethod.mpesa => Icons.phone_android,
        PaymentMethod.bank => Icons.account_balance,
        PaymentMethod.cash => Icons.payments_outlined,
        PaymentMethod.card => Icons.credit_card,
        PaymentMethod.other => Icons.receipt_long_outlined,
      };

  Future<void> _action(
    String value,
    Invoice invoice,
    BusinessProfile business,
  ) async {
    if (value == 'sent') {
      await _setStatus(
        invoice,
        InvoiceStatus.sent,
        'Mark invoice as sent?',
      );
      return;
    }
    if (value == 'viewed') {
      await _setStatus(
        invoice,
        InvoiceStatus.viewed,
        'Mark invoice as viewed?',
      );
      return;
    }
    if (value == 'edit') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateInvoiceScreen(invoice: invoice),
        ),
      );
      return;
    }
    if (value == 'duplicate') {
      final copy = invoice.copyWith(
        id: const Uuid().v4(),
        number:
            '${business.invoicePrefix}-${business.nextInvoiceNumber.toString().padLeft(4, '0')}',
        payments: const [],
        status: InvoiceStatus.draft,
        archived: false,
      );
      await ref.read(invoicesProvider.notifier).upsert(copy);
      await ref.read(businessProvider.notifier).save(
            business.copyWith(
              nextInvoiceNumber: business.nextInvoiceNumber + 1,
            ),
          );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetailsScreen(invoiceId: copy.id),
          ),
        );
      }
      return;
    }
    if (value == 'cancel') {
      await _setStatus(
        invoice,
        InvoiceStatus.cancelled,
        'Cancel invoice?',
      );
      return;
    }
    if (value == 'archive') {
      await _archive(invoice);
    }
  }

  Future<void> _setStatus(
    Invoice invoice,
    InvoiceStatus status,
    String title,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: const Text(
          'This changes the invoice status and can be reviewed later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await ref.read(invoicesProvider.notifier).upsert(
          invoice.copyWith(status: status),
        );
    if (mounted) setState(() {});
  }

  Future<void> _archive(Invoice invoice) async {
    await ref.read(invoicesProvider.notifier).upsert(
          invoice.copyWith(archived: true),
        );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _paymentAction(
    String value,
    Invoice invoice,
    Payment payment,
    BusinessProfile business,
  ) async {
    if (value == 'receipt') {
      final bytes = await InvoicePdfService.receiptBytes(
        invoice,
        payment,
        business,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            bytes: bytes,
            title: 'Receipt ${invoice.number}',
          ),
        ),
      );
      return;
    }

    if (value == 'delete') {
      final updated = invoice.copyWith(
        payments:
            invoice.payments.where((item) => item.id != payment.id).toList(),
        status: InvoiceStatus.sent,
      );
      await ref.read(invoicesProvider.notifier).upsert(updated);
      if (mounted) setState(() {});
    }
  }

  Future<void> _recordPayment(Invoice invoice) async {
    final amount = TextEditingController();
    final reference = TextEditingController();
    final note = TextEditingController();
    PaymentMethod method = PaymentMethod.mpesa;

    try {
      final result = await showDialog<Payment>(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Record payment'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: 'KSh ',
                      helperText:
                          'Balance: ${money.format(invoice.balance(invoice.vatRate))}',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<PaymentMethod>(
                    value: method,
                    decoration: const InputDecoration(labelText: 'Method'),
                    items: PaymentMethod.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => method = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reference,
                    decoration: const InputDecoration(labelText: 'Reference'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: note,
                    decoration: const InputDecoration(labelText: 'Note'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final value = double.tryParse(amount.text.trim()) ?? 0;
                  final balance = invoice.balance(invoice.vatRate);
                  if (value <= 0 || value > balance + 0.009) return;
                  Navigator.pop(
                    context,
                    Payment(
                      id: const Uuid().v4(),
                      date: DateTime.now(),
                      amount: value,
                      method: method,
                      reference: reference.text.trim(),
                      note: note.text.trim(),
                    ),
                  );
                },
                child: const Text('Record'),
              ),
            ],
          ),
        ),
      );

      if (result == null) return;
      final payments = [...invoice.payments, result];
      final remaining = invoice.balance(invoice.vatRate) - result.amount;
      final status = remaining <= 0.009
          ? InvoiceStatus.paid
          : InvoiceStatus.partiallyPaid;

      await ref.read(invoicesProvider.notifier).upsert(
            invoice.copyWith(payments: payments, status: status),
          );
      if (mounted) setState(() {});
    } finally {
      amount.dispose();
      reference.dispose();
      note.dispose();
    }
  }

  Future<void> _preview(Invoice invoice, BusinessProfile business) async {
    setState(() => busy = true);
    try {
      final bytes = await InvoicePdfService.invoiceBytes(invoice, business);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            bytes: bytes,
            title: invoice.number,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List bytes;
  final String title;

  const PdfPreviewScreen({
    super.key,
    required this.bytes,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(
        build: (_) async => bytes,
        pdfFileName: title.replaceAll(' ', '-'),
      ),
    );
  }
}
