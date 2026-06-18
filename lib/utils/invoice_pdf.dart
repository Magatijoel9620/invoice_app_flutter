// lib/utils/invoice_pdf_util.dart (or wherever your generateInvoicePdf is)
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../models/invoice.dart';
import '../models/pdf_settings.dart'; // Import PdfSettings


Future<Uint8List> generateInvoicePdf(
    Invoice invoice,
    PdfSettings settings,
    ) async {
  final pdf = pw.Document();

  // =========================
  // CALCULATIONS
  // =========================
  double subtotal = 0;

  for (final item in invoice.lineItems) {
    subtotal += item.quantity * item.unitPrice;
  }

  const double vatRate = 16.0;
  final double vatAmount = subtotal * (vatRate / 100);
  final double grandTotal = subtotal + vatAmount;

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),


      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            // =========================
            // HEADER BAR (BRANDING)
            // =========================
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              child: pw.Row(
                children: [
                  // LOGO (TOP LEFT)
                  if (settings.logoPath != null && settings.logoPath!.isNotEmpty)
                    pw.Container(
                      width: 50,
                      height: 50,
                      margin: const pw.EdgeInsets.only(right: 12),
                      child: pw.Image(
                        pw.MemoryImage(
                          File(settings.logoPath!).readAsBytesSync(),
                        ),
                        fit: pw.BoxFit.contain,
                      ),
                    ),

                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        settings.companyName,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'INVOICE',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // =========================
            // INVOICE INFO
            // =========================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Invoice #: ${invoice.invoiceNumber}'),
                    pw.Text('Client: ${invoice.clientName}'),
                    pw.Text(
                      'Date: ${invoice.date.toString().split(" ")[0]}',
                    ),
                  ],
                ),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data:
                  'Invoice#${invoice.invoiceNumber}\nClient:${invoice.clientName}\nCompany:${settings.companyName}',
                  width: 60,
                  height: 60,
                ),
              ],
            ),

            pw.SizedBox(height: 24),

            // =========================
            // ITEMS TABLE
            // =========================
            pw.Text(
              'Invoice Items',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 8),

            pw.TableHelper.fromTextArray(
              headers: ['#', 'Description', 'Qty', 'Unit Price', 'Total'],
              data: List.generate(invoice.lineItems.length, (index) {
                final item = invoice.lineItems[index];
                final lineTotal = item.quantity * item.unitPrice;

                return [
                  '${index + 1}',
                  item.description,
                  item.quantity.toString(),
                  item.unitPrice.toStringAsFixed(2),
                  lineTotal.toStringAsFixed(2),
                ];
              }),
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              cellPadding: const pw.EdgeInsets.all(6),
            ),

            pw.SizedBox(height: 16),

            // =========================
            // TOTAL BREAKDOWN
            // =========================
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Subtotal: ${subtotal.toStringAsFixed(2)}'),
                  pw.Text('VAT (16%): ${vatAmount.toStringAsFixed(2)}'),
                  pw.Divider(),
                  pw.Text(
                    'Grand Total: ${grandTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // =========================
            // PAYMENT INFO
            // =========================
            pw.Text(
              'Payment Details',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 8),

            if (settings.bankName.isNotEmpty)
              pw.Text('Bank: ${settings.bankName}'),
            if (settings.bankAccountNumber.isNotEmpty)
              pw.Text('Account: ${settings.bankAccountNumber}'),
            if (settings.mpesaTillNumber.isNotEmpty)
              pw.Text('M-Pesa Till: ${settings.mpesaTillNumber}'),
            if (settings.mpesaPhoneNumber.isNotEmpty)
              pw.Text('M-Pesa No: ${settings.mpesaPhoneNumber}'),

            pw.Spacer(),

            // =========================
            // FOOTER MESSAGE
            // =========================
            pw.Divider(),
            pw.Center(
              child: pw.Text(
                settings.thankYouMessage,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600,
                ),
              ),
            ),

            // =========================
            // FOOTER (PAGE NUMBERING)
            // =========================
            // footer: (context) {
            //   return pw.Container(
            //     alignment: pw.Alignment.centerRight,
            //     margin: const pw.EdgeInsets.only(top: 10),
            //     child: pw.Text(
            //       'Page ${context.pageNumber} of ${context.pagesCount}',
            //       style: const pw.TextStyle(
            //         fontSize: 10,
            //         color: PdfColors.grey600,
            //       ),
            //     ),
            //   );
            // },
          ],
        );
      },
    ),
  );

  return pdf.save();
}