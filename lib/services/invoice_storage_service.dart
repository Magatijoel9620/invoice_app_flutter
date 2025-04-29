import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice.dart';

class InvoiceStorageService {
  static const String _key = 'invoices';

  // Fetch all invoices
  static Future<List<Invoice>> getInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => Invoice.fromJson(json)).toList();
  }

  // Save a new invoice
  static Future<void> saveInvoice(Invoice invoice) async {
    final prefs = await SharedPreferences.getInstance();
    final invoices = await getInvoices();
    invoices.add(invoice);
    final encoded = jsonEncode(invoices.map((inv) => inv.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  // Delete an invoice
  static Future<void> deleteInvoice(Invoice invoice) async {
    final prefs = await SharedPreferences.getInstance();
    final invoices = await getInvoices();
    invoices.removeWhere((inv) => inv.id == invoice.id);
    final encoded = jsonEncode(invoices.map((inv) => inv.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  // Update an invoice
  static Future<void> updateInvoice(Invoice updatedInvoice, Invoice invoice) async {
    final prefs = await SharedPreferences.getInstance();
    final invoices = await getInvoices();
    final index = invoices.indexWhere((inv) => inv.id == updatedInvoice.id);
    if (index != -1) {
      invoices[index] = updatedInvoice;
      final encoded = jsonEncode(invoices.map((inv) => inv.toJson()).toList());
      await prefs.setString(_key, encoded);
    }
  }
}
