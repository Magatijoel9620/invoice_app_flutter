import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice.dart';
import '../models/business_profile.dart';
import 'local_store.dart';
import 'repositories.dart';

class MigrationService {
  static Future<void> run() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('ie_v2_migrated') == true) return;
    final raw = prefs.getString('invoices_data');
    if (raw != null && raw.isNotEmpty) {
      try {
        final old = (jsonDecode(raw) as List).map(
          (e) => Map<String, dynamic>.from(e as Map),
        );
        final invoices = <Map<String, dynamic>>[];
        for (final j in old) {
          final lines = (j['lineItems'] as List? ?? const []).map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return InvoiceLine(
              id: const Uuid().v4(),
              description: m['description'] as String? ?? '',
              quantity: (m['quantity'] as num?)?.toDouble() ?? 1,
              unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0,
            );
          }).toList();
          final issue =
              DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now();
          invoices.add(
            Invoice(
              id: j['id'] as String? ?? const Uuid().v4(),
              businessId: 'default',
              customerId: '',
              customerName: j['clientName'] as String? ?? 'Customer',
              number: j['invoiceNumber'] as String? ?? '',
              issueDate: issue,
              dueDate: issue.add(const Duration(days: 14)),
              lines: lines,
              archived: j['isArchived'] as bool? ?? false,
            ).toJson(),
          );
        }
        await LocalStore.writeList('ie_invoices_v2', invoices);
      } catch (_) {}
    }
    if (await LocalStore.readObject(BusinessRepository.key) == null) {
      await LocalStore.writeObject(
        BusinessRepository.key,
        BusinessProfile(
          id: 'default',
          name: 'My Business',
          businessType: 'Other',
        ).toJson(),
      );
    }
    await prefs.setBool('ie_v2_migrated', true);
  }
}
