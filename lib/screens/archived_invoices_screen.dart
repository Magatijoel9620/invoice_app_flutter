// screens/archived_invoices_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../services/invoice_storage_service.dart';
import '../utils/invoice_pdf.dart'; // For PDF functions
import 'package:printing/printing.dart'; // For PDF functions

class ArchivedInvoicesScreen extends StatefulWidget {
  // You might want to pass these if needed for consistency or actions
  // final bool isDarkMode;
  // final VoidCallback toggleTheme;

  const ArchivedInvoicesScreen({
    super.key,
    // required this.isDarkMode,
    // required this.toggleTheme,
  });

  @override
  State<ArchivedInvoicesScreen> createState() => _ArchivedInvoicesScreenState();
}

class _ArchivedInvoicesScreenState extends State<ArchivedInvoicesScreen> {
  List<Invoice> _archivedInvoices = [];
  bool _isLoading = true;
  String? _errorMessage;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');


  @override
  void initState() {
    super.initState();
    _loadArchivedInvoices();
  }

  Future<void> _loadArchivedInvoices({bool showLoadingIndicator = true}) async {
    if (mounted && showLoadingIndicator) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final invoices = await InvoiceStorageService.getArchivedInvoices();
      if (mounted) {
        setState(() {
          _archivedInvoices = invoices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading archived invoices: $e';
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
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showConfirmationDialog({
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

  Future<void> _handleUnarchiveInvoice(int index) async {
    if (index < 0 || index >= _archivedInvoices.length) return;
    final invoiceToUnarchive = _archivedInvoices[index];

    await _showConfirmationDialog(
      title: 'Confirm Unarchive',
      content: 'Are you sure you want to restore invoice "${invoiceToUnarchive.invoiceNumber}" to your active invoices?',
      confirmButtonText: 'Unarchive',
      confirmButtonColor: Theme.of(context).colorScheme.secondary, // Or another appropriate color
      onConfirm: () async {
        final updatedInvoice = invoiceToUnarchive.copyWith(isArchived: false);
        try {
          await InvoiceStorageService.updateInvoice(updatedInvoice);
          setState(() {
            _archivedInvoices.removeAt(index);
          });
          _showSuccessSnackBar('Invoice "${invoiceToUnarchive.invoiceNumber}" unarchived.');
        } catch (e) {
          _showErrorSnackBar('Failed to unarchive invoice: $e');
        }
      },
    );
  }

  Future<void> _handleDeleteArchivedInvoice(int index) async {
    if (index < 0 || index >= _archivedInvoices.length) return;
    final invoiceToDelete = _archivedInvoices[index];

    await _showConfirmationDialog(
      title: 'Confirm Permanent Deletion',
      content: 'This will permanently delete the archived invoice "${invoiceToDelete.invoiceNumber}". This action cannot be undone.',
      confirmButtonText: 'Delete Permanently',
      confirmButtonColor: Theme.of(context).colorScheme.error,
      onConfirm: () async {
        try {
          await InvoiceStorageService.deleteInvoicePermanently(invoiceToDelete.id); // Assuming deleteInvoice works by ID
          setState(() {
            _archivedInvoices.removeAt(index);
          });
          _showSuccessSnackBar('Archived invoice "${invoiceToDelete.invoiceNumber}" deleted permanently.');
        } catch (e) {
          _showErrorSnackBar('Failed to delete archived invoice: $e');
        }
      },
    );
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

  // View invoice could navigate to a detail screen or show a PDF preview
  void _navigateToViewInvoice(Invoice invoice) async {
    await _handlePrintInvoice(invoice);
  }


  @override
  Widget build(BuildContext context) {
    // This screen will have its own AppBar
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Invoices'),
        // Optionally add actions like refresh or theme toggle if not handled globally
      ),
      body: _buildArchivedBody(theme, colorScheme),
    );
  }

  Widget _buildArchivedBody(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _archivedInvoices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to Load Archived Invoices', style: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.error)),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () => _loadArchivedInvoices(),
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.errorContainer, foregroundColor: colorScheme.onErrorContainer),
              ),
            ],
          ),
        ),
      );
    }

    if (_archivedInvoices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 80, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
              const SizedBox(height: 20),
              Text('No Archived Invoices', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Invoices you archive will appear here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadArchivedInvoices(showLoadingIndicator: false),
      child: ListView.separated(
        itemCount: _archivedInvoices.length,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final invoice = _archivedInvoices[index];
          return _buildArchivedInvoiceListItem(invoice, index, theme, colorScheme);
        },
      ),
    );
  }

  Widget _buildArchivedInvoiceListItem(Invoice invoice, int index, ThemeData theme, ColorScheme colorScheme) {
    return Slidable(
      key: ValueKey(invoice.id),
      startActionPane: ActionPane( // Unarchive action on the left
        motion: const StretchMotion(),
        extentRatio: 0.3,
        children: [
          SlidableAction(
            onPressed: (_) => _handleUnarchiveInvoice(index),
            backgroundColor: colorScheme.secondaryContainer, // Or a distinct "unarchive" color
            foregroundColor: colorScheme.onSecondaryContainer,
            icon: Icons.unarchive_outlined,
            label: 'Unarchive',
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
          ),
        ],
      ),
      endActionPane: ActionPane( // Delete action on the right
        motion: const BehindMotion(),
        extentRatio: 0.3,
        children: [
          SlidableAction(
            onPressed: (_) => _handleDeleteArchivedInvoice(index),
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
            icon: Icons.delete_forever_outlined,
            label: 'Delete',
            borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
          ),
        ],
      ),
      child: Card(
        elevation: 1.5,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5), // Slightly different background for archived items
        child: InkWell(
          onTap: () => _navigateToViewInvoice(invoice), // Still allow viewing/printing
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.onSurfaceVariant.withOpacity(0.1),
                  foregroundColor: colorScheme.onSurfaceVariant,
                  child: const Icon(Icons.inventory_2_outlined),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.clientName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.normal, // Less emphasis than active
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${invoice.invoiceNumber}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Archived: ${_dateFormat.format(invoice.date.toLocal())}', // Or store an archivedDate
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
                        fontWeight: FontWeight.normal,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
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
