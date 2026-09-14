import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/business_profile.dart';
import '../models/invoice.dart';

class InvoicePdfService {
  static final _accent = PdfColor.fromHex('#0F766E');
  static final _ink = PdfColor.fromHex('#17211F');
  static final _muted = PdfColor.fromHex('#66736F');
  static final _soft = PdfColor.fromHex('#F1F6F4');
  static final _line = PdfColor.fromHex('#DCE6E2');

  static Future<Uint8List> invoiceBytes(
    Invoice invoice,
    BusinessProfile business,
  ) async {
    final doc = pw.Document(
      title: '${invoice.number} • ${business.name}',
      author: business.name,
    );
    final total = invoice.total(invoice.vatRate);
    final paid = invoice.amountPaid;
    final balance = invoice.balance(invoice.vatRate);
    final logo = await _loadLogo(business.logoPath);
    final status = _statusLabel(invoice, balance);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 36),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        header: (_) => _header(invoice, business, logo, status),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _line)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                business.name,
                style: pw.TextStyle(fontSize: 8, color: _muted),
              ),
              pw.Text(
                'Invoice ${invoice.number} • Page ${context.pageNumber}',
                style: pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ],
          ),
        ),
        build: (_) => [
          _billTo(invoice, business),
          pw.SizedBox(height: 18),
          _items(invoice),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 250,
              child: _totals(invoice, total, paid, balance),
            ),
          ),
          if (invoice.payments.isNotEmpty) ...[
            pw.SizedBox(height: 22),
            _sectionTitle('PAYMENT HISTORY'),
            pw.SizedBox(height: 7),
            _payments(invoice),
          ],
          if (_hasPaymentDetails(business)) ...[
            pw.SizedBox(height: 22),
            _paymentDetails(business),
          ],
          if (invoice.notes.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('NOTES'),
            pw.SizedBox(height: 5),
            pw.Text(invoice.notes, style: pw.TextStyle(color: _ink, fontSize: 9)),
          ],
          pw.SizedBox(height: 26),
          pw.Center(
            child: pw.Text(
              business.thankYouMessage,
              style: pw.TextStyle(
                fontSize: 10,
                color: _muted,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> receiptBytes(
    Invoice invoice,
    Payment payment,
    BusinessProfile business,
  ) async {
    final doc = pw.Document(
      title: 'Receipt • ${invoice.number}',
      author: business.name,
    );
    final logo = await _loadLogo(business.logoPath);
    final remaining = invoice.balance(invoice.vatRate);

    doc.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(34),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _businessHeader(business, logo),
            pw.SizedBox(height: 26),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              decoration: pw.BoxDecoration(
                color: _accent,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'PAYMENT RECEIPT',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 17,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    invoice.number,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            _receiptRow('Receipt date', _date(payment.date)),
            _receiptRow('Customer', invoice.customerName),
            _receiptRow('Payment method', _method(payment.method)),
            if (payment.reference.isNotEmpty)
              _receiptRow('Reference', payment.reference),
            pw.SizedBox(height: 18),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: _soft,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                border: pw.Border.all(color: _line),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'AMOUNT RECEIVED',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: _muted,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    _money(payment.amount),
                    style: pw.TextStyle(
                      fontSize: 24,
                      color: _accent,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            _receiptRow('Invoice total', _money(invoice.total(invoice.vatRate))),
            _receiptRow('Total paid', _money(invoice.amountPaid)),
            _receiptRow('Balance remaining', _money(remaining)),
            if (payment.note.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              _sectionTitle('NOTE'),
              pw.SizedBox(height: 5),
              pw.Text(payment.note, style: pw.TextStyle(fontSize: 9, color: _ink)),
            ],
            pw.Spacer(),
            pw.Divider(color: _line),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Thank you for your payment.',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: _muted,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  static Future<pw.MemoryImage?> _loadLogo(String path) async {
    if (path.isEmpty) return null;
    try {
      return pw.MemoryImage(await File(path).readAsBytes());
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _header(
    Invoice invoice,
    BusinessProfile business,
    pw.MemoryImage? logo,
    String status,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: _businessHeader(business, logo)),
          pw.SizedBox(width: 20),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  color: _accent,
                  fontSize: 25,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                invoice.number,
                style: pw.TextStyle(
                  color: _ink,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 7),
              _statusPill(status),
              pw.SizedBox(height: 7),
              pw.Text('Issued ${_date(invoice.issueDate)}', style: pw.TextStyle(fontSize: 8, color: _muted)),
              pw.Text('Due ${_date(invoice.dueDate)}', style: pw.TextStyle(fontSize: 8, color: _muted)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _businessHeader(
    BusinessProfile b,
    pw.MemoryImage? logo,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null)
          pw.Container(
            width: 74,
            height: 42,
            margin: const pw.EdgeInsets.only(bottom: 7),
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          ),
        pw.Text(
          b.name,
          style: pw.TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (b.businessType.isNotEmpty)
          pw.Text(b.businessType, style: pw.TextStyle(color: _muted, fontSize: 8)),
        if (b.address.isNotEmpty)
          pw.Text(b.address, style: pw.TextStyle(color: _muted, fontSize: 8)),
        if (b.phone.isNotEmpty)
          pw.Text(b.phone, style: pw.TextStyle(color: _muted, fontSize: 8)),
        if (b.email.isNotEmpty)
          pw.Text(b.email, style: pw.TextStyle(color: _muted, fontSize: 8)),
        if (b.kraPin.isNotEmpty)
          pw.Text('KRA PIN: ${b.kraPin}', style: pw.TextStyle(color: _muted, fontSize: 8)),
      ],
    );
  }

  static pw.Widget _billTo(Invoice i, BusinessProfile b) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(13),
      decoration: pw.BoxDecoration(
        color: _soft,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(9)),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _sectionTitle('BILL TO'),
                pw.SizedBox(height: 5),
                pw.Text(
                  i.customerName,
                  style: pw.TextStyle(
                    color: _ink,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                if (i.customerId.isNotEmpty)
                  pw.Text('Customer ID: ${i.customerId}', style: pw.TextStyle(color: _muted, fontSize: 8)),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Currency', style: pw.TextStyle(color: _muted, fontSize: 7)),
              pw.Text(b.currency, style: pw.TextStyle(color: _ink, fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _items(Invoice i) {
    return pw.TableHelper.fromTextArray(
      headers: const ['Description', 'Qty', 'Unit price', 'Amount'],
      data: i.lines
          .map((l) => [
                l.description,
                _qty(l.quantity),
                _money(l.unitPrice),
                _money(l.total),
              ])
          .toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 8,
      ),
      headerDecoration: pw.BoxDecoration(color: _accent),
      cellStyle: pw.TextStyle(color: _ink, fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _line, width: .5),
        bottom: pw.BorderSide(color: _line),
      ),
    );
  }

  static pw.Widget _totals(Invoice i, double total, double paid, double balance) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _soft,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(9)),
      ),
      child: pw.Column(
        children: [
          _totalRow('Subtotal', _money(i.subtotal)),
          if (i.discount > 0) _totalRow('Discount', '− ${_money(i.discount)}'),
          if (i.vatEnabled)
            _totalRow('VAT (${i.vatRate.toStringAsFixed(0)}%)', _money(i.tax(i.vatRate))),
          pw.Divider(color: _line),
          _totalRow('TOTAL', _money(total), bold: true, accent: true),
          _totalRow('Paid', _money(paid)),
          _totalRow('Balance due', _money(balance), bold: true),
        ],
      ),
    );
  }

  static pw.Widget _payments(Invoice i) => pw.TableHelper.fromTextArray(
        headers: const ['Date', 'Method', 'Reference', 'Amount'],
        data: i.payments
            .map((p) => [
                  _date(p.date),
                  _method(p.method),
                  p.reference.isEmpty ? '—' : p.reference,
                  _money(p.amount),
                ])
            .toList(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
        headerDecoration: pw.BoxDecoration(color: _soft),
        cellStyle: pw.TextStyle(fontSize: 8, color: _ink),
        cellPadding: const pw.EdgeInsets.all(5),
      );

  static pw.Widget _paymentDetails(BusinessProfile b) => pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _line),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(9)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _sectionTitle('PAYMENT DETAILS'),
            pw.SizedBox(height: 6),
            if (b.mpesaTill.isNotEmpty) pw.Text('M-Pesa Till: ${b.mpesaTill}', style: pw.TextStyle(fontSize: 8, color: _ink)),
            if (b.paybill.isNotEmpty) pw.Text('Paybill: ${b.paybill}', style: pw.TextStyle(fontSize: 8, color: _ink)),
            if (b.bankName.isNotEmpty)
              pw.Text('Bank: ${b.bankName}${b.bankAccount.isNotEmpty ? ' • ${b.bankAccount}' : ''}', style: pw.TextStyle(fontSize: 8, color: _ink)),
          ],
        ),
      );

  static pw.Widget _sectionTitle(String text) => pw.Text(
        text,
        style: pw.TextStyle(
          color: _accent,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      );

  static pw.Widget _statusPill(String text) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(
          color: _soft,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
        ),
        child: pw.Text(
          text.toUpperCase(),
          style: pw.TextStyle(color: _accent, fontSize: 7, fontWeight: pw.FontWeight.bold),
        ),
      );

  static pw.Widget _totalRow(
    String label,
    String value, {
    bool bold = false,
    bool accent = false,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                color: accent ? _accent : _muted,
                fontSize: accent ? 10 : 8,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: accent ? _accent : _ink,
                fontSize: accent ? 11 : 8,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      );

  static pw.Widget _receiptRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: pw.TextStyle(color: _muted, fontSize: 9)),
            pw.SizedBox(width: 15),
            pw.Expanded(
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(color: _ink, fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      );

  static bool _hasPaymentDetails(BusinessProfile b) =>
      b.mpesaTill.isNotEmpty || b.paybill.isNotEmpty || b.bankName.isNotEmpty;

  static String _statusLabel(Invoice i, double balance) {
    if (i.status == InvoiceStatus.cancelled) return 'Cancelled';
    if (balance <= .009) return 'Paid';
    if (i.amountPaid > .009) return 'Partially paid';
    if (i.status == InvoiceStatus.draft) return 'Draft';
    if (DateTime.now().isAfter(i.dueDate)) return 'Overdue';
    return i.status.name == 'viewed' ? 'Viewed' : 'Sent';
  }

  static String _method(PaymentMethod method) =>
      method.name == 'mpesa' ? 'M-Pesa' : method.name[0].toUpperCase() + method.name.substring(1);

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _qty(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  static String _money(double v) => 'KSh ${v.toStringAsFixed(2)}';

  static Future<File> writeTemp(Uint8List bytes, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    return file.writeAsBytes(bytes, flush: true);
  }
}
