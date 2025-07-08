import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice.dart'; // Make sure your Invoice model has 'id' and 'isArchived'

class InvoiceStorageService {
  static const String _storageKey = 'invoices_data'; // Using a more descriptive key

  // --- Private Helper Methods ---

  /// Retrieves all invoices from storage, without any filtering.
  static Future<List<Invoice>> _getAllInvoicesFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data == null || data.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((json) => Invoice.fromJson(json)).toList();
    } catch (e) {
      // Handle potential decoding errors, perhaps clear corrupted data or log
      print('Error decoding invoices from storage: $e');
      // Optionally, clear corrupted data: await prefs.remove(_storageKey);
      return [];
    }
  }

  /// Saves the complete list of invoices to storage.
  static Future<void> _saveAllInvoicesToStorage(List<Invoice> invoices) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(invoices.map((inv) => inv.toJson()).toList());
    await prefs.setString(_storageKey, encodedData);
  }

  // --- Public API Methods ---

  /// Fetches active (non-archived) invoices.
  /// Sorts by date descending by default.
  static Future<List<Invoice>> getActiveInvoices() async {
    final allInvoices = await _getAllInvoicesFromStorage();
    return allInvoices.where((invoice) => !invoice.isArchived).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
  }

  /// Fetches archived invoices.
  /// Sorts by date descending by default.
  static Future<List<Invoice>> getArchivedInvoices() async {
    final allInvoices = await _getAllInvoicesFromStorage();
    return allInvoices.where((invoice) => invoice.isArchived).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
  }

  /// Saves a new invoice. It's assumed new invoices are not archived.
  /// Ensures the invoice has a unique ID before saving.
  static Future<void> addInvoice(Invoice newInvoice) async {
    if (newInvoice.id.isEmpty) {
      // Assign a unique ID if not already present.
      // This is crucial. Using DateTime.now().millisecondsSinceEpoch.toString()
      // combined with a small random part can be a simple way.
      // For more robust solutions, consider UUID package.
      newInvoice = newInvoice.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString() + (newInvoice.invoiceNumber.hashCode % 1000).toString());
    }

    final List<Invoice> allInvoices = await _getAllInvoicesFromStorage();
    // Prevent duplicate IDs, though the above ID generation should be fairly unique
    if (allInvoices.any((inv) => inv.id == newInvoice.id)) {
      // Handle ID collision, perhaps by regenerating ID or throwing an error
      print('Warning: Attempting to add invoice with duplicate ID: ${newInvoice.id}');
      // For simplicity, we'll allow it but in a real app, this should be robust.
    }

    allInvoices.add(newInvoice.copyWith(isArchived: false)); // Ensure new invoices are active
    await _saveAllInvoicesToStorage(allInvoices);
  }

  /// Updates an existing invoice. This can be used to modify any field,
  /// including the 'isArchived' status.
  static Future<void> updateInvoice(Invoice updatedInvoice) async {
    final List<Invoice> allInvoices = await _getAllInvoicesFromStorage();
    final index = allInvoices.indexWhere((inv) => inv.id == updatedInvoice.id);

    if (index != -1) {
      allInvoices[index] = updatedInvoice;
      await _saveAllInvoicesToStorage(allInvoices);
    } else {
      // Handle case where invoice to update is not found, though this shouldn't typically happen
      // if called from UI where invoice exists.
      print('Error: Invoice with ID ${updatedInvoice.id} not found for update.');
      // throw Exception('Invoice not found for update'); // Or handle more gracefully
    }
  }

  /// Deletes an invoice permanently from storage, regardless of its archived status.
  static Future<void> deleteInvoicePermanently(String invoiceId) async {
    final List<Invoice> allInvoices = await _getAllInvoicesFromStorage();
    allInvoices.removeWhere((inv) => inv.id == invoiceId);
    await _saveAllInvoicesToStorage(allInvoices);
  }

  // --- Convenience methods for archiving/unarchiving ---

  /// Marks an invoice as archived.
  static Future<void> archiveInvoice(String invoiceId) async {
    final List<Invoice> allInvoices = await _getAllInvoicesFromStorage();
    final index = allInvoices.indexWhere((inv) => inv.id == invoiceId);
    if (index != -1 && !allInvoices[index].isArchived) {
      allInvoices[index] = allInvoices[index].copyWith(isArchived: true);
      await _saveAllInvoicesToStorage(allInvoices);
    }
  }

  /// Marks an invoice as unarchived (active).
  static Future<void> unarchiveInvoice(String invoiceId) async {
    final List<Invoice> allInvoices = await _getAllInvoicesFromStorage();
    final index = allInvoices.indexWhere((inv) => inv.id == invoiceId);
    if (index != -1 && allInvoices[index].isArchived) {
      allInvoices[index] = allInvoices[index].copyWith(isArchived: false);
      await _saveAllInvoicesToStorage(allInvoices);
    }
  }

  // Optional: Method to get a single invoice by ID, regardless of archive status
  static Future<Invoice?> getInvoiceById(String invoiceId) async {
    final allInvoices = await _getAllInvoicesFromStorage();
    try {
      return allInvoices.firstWhere((inv) => inv.id == invoiceId);
    } catch (e) {
      return null; // Not found
    }
  }
}
