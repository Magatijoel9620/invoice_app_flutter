import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../models/invoice.dart'; // Make sure this imports your updated Invoice model

Future<Uint8List> generateInvoicePdf(Invoice invoice) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Text(
              'Hempon Group',
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),

            // Invoice and Client Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Invoice #: ${invoice.invoiceNumber}',
                      style: pw.TextStyle(fontSize: 16),
                    ),
                    pw.Text(
                      'Client: ${invoice.clientName}',
                      style: pw.TextStyle(fontSize: 16),
                    ),
                    pw.Text(
                      'Date: ${invoice.date.toString().split(" ")[0]}',
                      style: pw.TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: 'Invoice#${invoice.invoiceNumber}',
                  width: 60,
                  height: 60,
                ),
              ],
            ),

            pw.SizedBox(height: 32),

            // Items Table
            pw.Text(
              'Invoice Items',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),

            // Table for line items
            pw.Table.fromTextArray(
              headers: ['#', 'Description', 'Quantity', 'Unit Price', 'Total'],
              data: List.generate(invoice.lineItems.length, (index) {
                final item = invoice.lineItems[index];
                return [
                  '${index + 1}',
                  item.description,
                  item.quantity.toString(),
                  item.unitPrice.toStringAsFixed(2),
                  (item.quantity * item.unitPrice).toStringAsFixed(2),
                ];
              }),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(8),
            ),

            // Total Payment Section
            pw.SizedBox(height: 12),

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'Total: ',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    invoice.totalAmount.toStringAsFixed(2),
                    style: pw.TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 32),

            // Payment Info Section
            pw.Text(
              'Payment Details',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Bank Name: KCB'),
            pw.Text('Account Name: Magati Joel Omwoyo'),
            pw.Text('Account Number: 1223534448'),
            pw.SizedBox(height: 8),
            pw.Text('M-Pesa Till: 8804788'),
            pw.Text('Account: Joel Omwoyo Magati'),
            pw.SizedBox(height: 8),
            pw.Text('M-Pesa Phone No: +254711879129'),
            pw.Text('Account: Magati Joel'),

            pw.Spacer(),

            // Footer
            pw.Divider(),
            pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                fontSize: 14,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey700,
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
