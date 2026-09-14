import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/business_profile.dart';
import '../models/invoice.dart';

class ReportExportService {
  static Future<void> shareCsv(
    List<Invoice> invoices,
    BusinessProfile business,
  ) async {
    final rows = <List<String>>[
      [
        'Invoice',
        'Customer',
        'Issue Date',
        'Due Date',
        'Status',
        'Subtotal',
        'VAT',
        'Total',
        'Paid',
        'Balance',
      ],
      ...invoices.map((i) {
        final subtotal = i.subtotal;
        final vat = i.total(i.vatRate) - subtotal;
        final total = i.total(i.vatRate);
        return [
          i.number,
          i.customerName,
          _date(i.issueDate),
          _date(i.dueDate),
          i.status.name,
          subtotal.toStringAsFixed(2),
          vat.toStringAsFixed(2),
          total.toStringAsFixed(2),
          i.amountPaid.toStringAsFixed(2),
          i.balance(i.vatRate).toStringAsFixed(2),
        ];
      }),
    ];

    final csv = rows.map((row) => row.map(_csv).join(',')).join('\n');
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/InvoiceEasy-Report-${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csv, encoding: utf8);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Invoice report from ${business.name}',
      ),
    );
  }

  static Future<void> sharePdf(
    List<Invoice> invoices,
    BusinessProfile business,
  ) async {
    final doc = pw.Document(
      title: 'Invoice report • ${business.name}',
      author: business.name,
    );

    final total = invoices.fold<double>(
      0,
      (sum, i) => sum + i.total(i.vatRate),
    );
    final paid = invoices.fold<double>(0, (sum, i) => sum + i.amountPaid);
    final balance = invoices.fold<double>(
      0,
      (sum, i) => sum + i.balance(i.vatRate),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          pw.Text(
            business.name,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Invoice report',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 18),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _summaryRow('Invoices', '${invoices.length}'),
              _summaryRow('Invoiced', _money(total, business.currency)),
              _summaryRow('Collected', _money(paid, business.currency)),
              _summaryRow('Outstanding', _money(balance, business.currency)),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Invoice',
              'Customer',
              'Date',
              'Total',
              'Paid',
              'Balance',
            ],
            data: invoices
                .map(
                  (i) => [
                    i.number,
                    i.customerName,
                    _date(i.issueDate),
                    _money(i.total(i.vatRate), business.currency),
                    _money(i.amountPaid, business.currency),
                    _money(i.balance(i.vatRate), business.currency),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/InvoiceEasy-Report-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await doc.save());
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Invoice report from ${business.name}',
      ),
    );
  }

  static pw.TableRow _summaryRow(String label, String value) => pw.TableRow(
    children: [
      pw.Padding(padding: const pw.EdgeInsets.all(7), child: pw.Text(label)),
      pw.Padding(
        padding: const pw.EdgeInsets.all(7),
        child: pw.Text(
          value,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ),
    ],
  );

  static String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _money(double value, String currency) =>
      '$currency ${value.toStringAsFixed(2)}';
}
