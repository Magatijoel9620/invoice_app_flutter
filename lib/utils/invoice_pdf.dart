// lib/utils/invoice_pdf_util.dart (or wherever your generateInvoicePdf is)
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../models/invoice.dart';
import '../models/pdf_settings.dart'; // Import PdfSettings

Future<Uint8List> generateInvoicePdf(Invoice invoice, PdfSettings settings) async { // Add settings parameter
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
              settings.companyName, // Use from settings
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),

            // ... (Invoice and Client Info - remains the same) ...
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
                  data: 'Invoice#${invoice.invoiceNumber}\nClient:${invoice.clientName}\nCompany:${settings.companyName}', // Add more data to QR
                  width: 60,
                  height: 60,
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // ... (Items Table - remains the same) ...
            pw.Text(
              'Invoice Items',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
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


            // Payment Info Section - Use from settings
            pw.Text(
              'Payment Details',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            if (settings.bankName.isNotEmpty) pw.Text('Bank Name: ${settings.bankName}'),
            if (settings.bankAccountName.isNotEmpty) pw.Text('Account Name: ${settings.bankAccountName}'),
            if (settings.bankAccountNumber.isNotEmpty) pw.Text('Account Number: ${settings.bankAccountNumber}'),

            if (settings.mpesaTillNumber.isNotEmpty || settings.mpesaPhoneNumber.isNotEmpty) pw.SizedBox(height: 8),

            if (settings.mpesaTillNumber.isNotEmpty) pw.Text('M-Pesa Till: ${settings.mpesaTillNumber}'),
            if (settings.mpesaTillAccountName.isNotEmpty) pw.Text('Account: ${settings.mpesaTillAccountName}'),

            if (settings.mpesaTillNumber.isNotEmpty && settings.mpesaPhoneNumber.isNotEmpty) pw.SizedBox(height: 8),

            if (settings.mpesaPhoneNumber.isNotEmpty) pw.Text('M-Pesa Phone No: ${settings.mpesaPhoneNumber}'),
            if (settings.mpesaPhoneAccountName.isNotEmpty) pw.Text('Account: ${settings.mpesaPhoneAccountName}'),

            pw.Spacer(),

            // Footer
            pw.Divider(),
            pw.Text(
              settings.thankYouMessage, // Use from settings
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

