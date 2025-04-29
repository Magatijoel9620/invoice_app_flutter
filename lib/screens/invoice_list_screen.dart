import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import 'package:intl/intl.dart';
import '../screens/invoice_entry_screen.dart';
import '../services/invoice_storage_service.dart';
import '../utils/invoice_pdf.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'dart:html' as html show AnchorElement, Blob, Url; // Import only used classes


import 'package:printing/printing.dart'; // Still used for native/mobile

class InvoiceListScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const InvoiceListScreen({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  List<Invoice> _invoices = [];

  @override
  void initState() {
    super.initState();

    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      final invoices = await InvoiceStorageService.getInvoices();
      setState(() {
        _invoices = invoices;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading invoices: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this invoice?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                _deleteInvoice(index);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showArchiveConfirmationDialog(int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Archiving'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to archive this invoice?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Archive'),
              onPressed: () {
                _archiveInvoice(index);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteInvoice(int index) {
    final invoiceToRemove = _invoices[index];
    setState(() {
      _invoices.removeAt(index);
    });
    InvoiceStorageService.deleteInvoice(invoiceToRemove);
  }

  void _archiveInvoice(int index) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invoice archived!')));
  }

  void _viewInvoice(Invoice invoice) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('View Invoice!')));
  }

  void _editInvoice(Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => InvoiceEntryScreen(
              existingInvoice: invoice,
              isDarkMode: widget.isDarkMode,
              toggleTheme: widget.toggleTheme,
            ),
      ),
    ).then((_) => _loadInvoices());
  }
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  return Scaffold(
    appBar: AppBar(
      title: const Text('Invoices'),
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadInvoices),
        IconButton(
          icon: Icon(
            widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
          ),
          onPressed: widget.toggleTheme,
        ),
      ],
    ),
    body: _invoices.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'No invoices yet!',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          )
        : ListView.separated(
            itemCount: _invoices.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final invoice = _invoices[index];
              return Slidable(
                key: Key(invoice.invoiceNumber),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) => _showArchiveConfirmationDialog(index),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      icon: Icons.archive,
                      label: 'Archive',
                    ),
                    SlidableAction(
                      onPressed: (_) => _showDeleteConfirmationDialog(index),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Icon(Icons.receipt, color: theme.colorScheme.primary),
                    ),
                    title: Text(
                      invoice.clientName,
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invoice #: ${invoice.invoiceNumber}'),
                          Text('Date: ${DateFormat('yyyy-MM-dd').format(invoice.date)}'),
                        ],
                      ),
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Print',
                          icon: const Icon(Icons.print),
                          onPressed: () => _printInvoice(invoice),
                        ),
                        IconButton(
                          tooltip: 'Download',
                          icon: const Icon(Icons.download),
                          onPressed: () => _downloadInvoice(invoice),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editInvoice(invoice),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
  );
}

  }
Future<void> _printInvoice(Invoice invoice) async {
  try {
    final pdf = await generateInvoicePdf(invoice);
    if (kIsWeb) {      
       // Conditional import and usage for web-only code
        final blob = html.Blob([pdf], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'Invoice-${invoice.invoiceNumber}.pdf')
          ..style.display = 'none'
          ..click();
        html.Url.revokeObjectUrl(url);


    } else {
      await Printing.layoutPdf(onLayout: (_) => pdf);
    }
  } catch (e) {
    print('Print error: $e');
  }
}

Future<void> _downloadInvoice(Invoice invoice) async {
  try {
    final pdf = await generateInvoicePdf(invoice);
    final name = 'Invoice-${invoice.invoiceNumber}.pdf';
    if (kIsWeb) {
       // Conditional import and usage for web-only code
        final blob = html.Blob([pdf], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', name)
          ..style.display = 'none'
          ..click();
        html.Url.revokeObjectUrl(url);
    } else {
      await Printing.sharePdf(bytes: pdf, filename: name);
    }
  } catch (e) {
    print('Download error: $e');
  }
}
