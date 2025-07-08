// ignore_for_file: unused_element, avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
// Keep for conditional PDF logic if needed

import '../models/invoice.dart';
import '../screens/invoice_entry_screen.dart';
import '../services/invoice_storage_service.dart';
import '../utils/invoice_pdf.dart';

// Removed duplicate import of printing/printing.dart

class InvoiceListScreen extends StatefulWidget {
  // These are passed by MainScreen if the AppBar actions (like theme toggle)
  // are still desired to be controllable from here, OR if InvoiceListScreen
  // needs to pass them down further. If MainScreen handles all AppBar actions,
  // these might not be strictly necessary here unless other UI elements in
  // InvoiceListScreen depend on isDarkMode.
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
  bool _isLoading = true;
  String? _errorMessage;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  // For currency formatting, ensure 'intl' package is correctly imported and used
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$'); // Adjust locale & symbol

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices({bool showLoadingIndicator = true}) async {
    if (mounted && showLoadingIndicator) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final invoices = await InvoiceStorageService.getActiveInvoices();
      if (mounted) {
        setState(() {
          _invoices = invoices..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading invoices: $e';
          _isLoading = false;
        });
        _showErrorSnackBar(_errorMessage!);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700, // Or use theme success color
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmButtonText,
    required VoidCallback onConfirm,
    Color? confirmButtonColor,
  }) async {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: theme.textTheme.titleLarge),
          content: Text(content, style: theme.textTheme.bodyMedium),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: confirmButtonColor ?? theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(confirmButtonText),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteInvoice(int index) async {
    if (index < 0 || index >= _invoices.length) return;
    final invoiceToDelete = _invoices[index];

    await _showConfirmationDialog(
      context: context,
      title: 'Confirm Deletion',
      content: 'Are you sure you want to permanently delete invoice "${invoiceToDelete.invoiceNumber}" for ${invoiceToDelete.clientName}?',
      confirmButtonText: 'Delete',
      confirmButtonColor: Theme.of(context).colorScheme.error,
      onConfirm: () async {
        // Optimistically remove from UI
        final originalInvoices = List<Invoice>.from(_invoices);
        final removedInvoice = _invoices.removeAt(index);
        setState(() {});

        try {
          await InvoiceStorageService.deleteInvoicePermanently(invoiceToDelete.id);
          _showSuccessSnackBar('Invoice "${invoiceToDelete.invoiceNumber}" deleted.');
        } catch (e) {
          _showErrorSnackBar('Failed to delete invoice: $e');
          // Revert UI change if deletion failed
          if (mounted) {
            setState(() {
              _invoices = originalInvoices;
            });
          }
        }
      },
    );
  }

  Future<void> _handleArchiveInvoice(int index) async {
    if (index < 0 || index >= _invoices.length) return;
    final invoiceToArchive = _invoices[index];
    // TODO: Implement actual archive logic
    await _showConfirmationDialog(
      context: context,
      title: 'Confirm Archive',
      content: 'Are you sure you want to archive invoice "${invoiceToArchive.invoiceNumber}"?',
      confirmButtonText: 'Archive',
      confirmButtonColor: Colors.orange.shade700,
      onConfirm: () {
        // Placeholder: Implement actual archiving logic
        // e.g., invoiceToArchive.isArchived = true; InvoiceStorageService.updateInvoice(invoiceToArchive);
        // Then filter archived invoices from the main list or move them.
        setState(() {
          // For now, just simulate by removing from this active list
          _invoices.removeAt(index);
        });
        _showSuccessSnackBar('Invoice "${invoiceToArchive.invoiceNumber}" archived (simulation).');
        // _loadInvoices(showLoadingIndicator: false); // Refresh list if archiving changes data source
      },
    );
  }

  void _navigateToEditInvoice(Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceEntryScreen(
          existingInvoice: invoice,
          isDarkMode: widget.isDarkMode, // Pass theme info
          toggleTheme: widget.toggleTheme,
        ),
      ),
    ).then((result) {
      if (result == true) { // Assuming InvoiceEntryScreen returns true on save
        _loadInvoices(showLoadingIndicator: false);
      }
    });
  }

  // View invoice could navigate to a detail screen or show a PDF preview
  void _navigateToViewInvoice(Invoice invoice) async {
    // For now, let's use the print functionality as a "view"
    // In a real app, you might have a dedicated InvoiceDetailScreen(invoice: invoice)
    // or use an in-app PDF viewer.
    await _handlePrintInvoice(invoice);
  }

  Future<void> _handlePrintInvoice(Invoice invoice) async {
    try {
      final pdfBytes = await generateInvoicePdf(invoice);
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Invoice-${invoice.invoiceNumber}.pdf',
      );
    } catch (e) {
      _showErrorSnackBar('Print error: $e');
      debugPrint('Print error: $e');
    }
  }

  Future<void> _handleDownloadInvoice(Invoice invoice) async {
    try {
      final pdfBytes = await generateInvoicePdf(invoice);
      final name = 'Invoice-${invoice.invoiceNumber}.pdf';
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: name,
      );
    } catch (e) {
      _showErrorSnackBar('Download/Share error: $e');
      debugPrint('Download/Share error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // This Scaffold is only needed if InvoiceListScreen is NOT part of MainScreen's IndexedStack
    // OR if it needs its own FloatingActionButton independent of MainScreen.
    // Assuming it's part of MainScreen's body, we don't need a Scaffold here.
    // The AppBar is provided by MainScreen.

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // print("--- InvoiceListScreen Build ---");
    // print("Current Scaffold Bg: ${theme.scaffoldBackgroundColor}");
    // print("Current Card Color (from theme): ${theme.cardTheme.color ?? theme.cardColor}");
    // print("Current Text Color (bodyMedium): ${theme.textTheme.bodyMedium?.color}");
    // print("isLoading: $_isLoading, errorMessage: $_errorMessage, invoices.length: ${_invoices.length}");
    // print("-----------------------------");

    // The body content:
    return _buildBody(theme, colorScheme);
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _invoices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to Load Invoices', style: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.error)),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () => _loadInvoices(),
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.errorContainer, foregroundColor: colorScheme.onErrorContainer),
              ),
            ],
          ),
        ),
      );
    }

    if (_invoices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined, size: 80, color: colorScheme.primary.withOpacity(0.7)),
              const SizedBox(height: 20),
              Text('No Invoices Yet!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Tap the "+" button on the main navigation to create your first invoice.', // Adjusted message
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadInvoices(showLoadingIndicator: false),
      child: ListView.separated(
        itemCount: _invoices.length,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final invoice = _invoices[index];
          return _buildInvoiceListItem(invoice, index, theme, colorScheme);
        },
      ),
    );
  }

  Widget _buildInvoiceListItem(Invoice invoice, int index, ThemeData theme, ColorScheme colorScheme) {
    return Slidable(
      key: ValueKey(invoice.id), // Use a unique ID
      startActionPane: ActionPane(
        motion: const StretchMotion(), // Different motion
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _navigateToEditInvoice(invoice),
            backgroundColor: colorScheme.tertiaryContainer,
            foregroundColor: colorScheme.onTertiaryContainer,
            icon: Icons.edit_outlined,
            label: 'Edit',
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(), // Different motion
        extentRatio: 0.65, // Adjusted for three actions
        children: [
          SlidableAction( // PDF Actions can be grouped or individual
            onPressed: (_) => _handlePrintInvoice(invoice),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            icon: Icons.print_outlined,
            label: 'Print',
          ),
          SlidableAction(
            onPressed: (_) => _handleArchiveInvoice(index),
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
            icon: Icons.archive_outlined,
            label: 'Archive',
          ),
          SlidableAction(
            onPressed: (_) => _handleDeleteInvoice(index),
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
          ),
        ],
      ),
      child: Card(
        elevation: 2.0,
        margin: EdgeInsets.zero, // Slidable often handles margin/padding
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _navigateToViewInvoice(invoice),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer.withOpacity(0.7),
                  foregroundColor: colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.receipt_outlined),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.clientName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${invoice.invoiceNumber}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _dateFormat.format(invoice.date.toLocal()), // Use toLocal() for display
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currencyFormat.format(invoice.totalAmount),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    // You could add a status indicator here if invoices have statuses
                    // e.g., Text("Paid", style: TextStyle(color: Colors.green, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
