import 'package:share_plus/share_plus.dart';
import 'pdf_service.dart';
import '../models/business_profile.dart';
import '../models/invoice.dart';

class ShareService {
  static Future<void> shareInvoice(
    Invoice invoice,
    BusinessProfile business,
  ) async {
    final bytes = await InvoicePdfService.invoiceBytes(invoice, business);
    final file = await InvoicePdfService.writeTemp(
      bytes,
      'Invoice-${invoice.number}.pdf',
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Invoice ${invoice.number} from ${business.name}',
      ),
    );
  }

  static Future<void> shareReceipt(
    Invoice invoice,
    Payment payment,
    BusinessProfile business,
  ) async {
    final bytes = await InvoicePdfService.receiptBytes(
      invoice,
      payment,
      business,
    );
    final file = await InvoicePdfService.writeTemp(
      bytes,
      'Receipt-${invoice.number}-${payment.id}.pdf',
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Payment receipt for ${invoice.number}',
      ),
    );
  }
}
