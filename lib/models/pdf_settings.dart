// lib/models/pdf_settings.dart

class PdfSettings {
  String companyName;
  String bankName;
  String bankAccountName;
  String bankAccountNumber;
  String mpesaTillNumber;
  String mpesaTillAccountName; // Often the business name or individual's name
  String mpesaPhoneNumber;
  String mpesaPhoneAccountName; // Often the individual's name
  String thankYouMessage;

  PdfSettings({
    this.companyName = 'Hempon Group', // Default value
    this.bankName = 'KCB',
    this.bankAccountName = 'Magati Joel Omwoyo',
    this.bankAccountNumber = '1223534448',
    this.mpesaTillNumber = '8804788',
    this.mpesaTillAccountName = 'Joel Omwoyo Magati',
    this.mpesaPhoneNumber = '+254711879129',
    this.mpesaPhoneAccountName = 'Magati Joel',
    this.thankYouMessage = 'Thank you for your business!',
  });

  // Method to convert PdfSettings to a Map (for JSON storage)
  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'bankName': bankName,
      'bankAccountName': bankAccountName,
      'bankAccountNumber': bankAccountNumber,
      'mpesaTillNumber': mpesaTillNumber,
      'mpesaTillAccountName': mpesaTillAccountName,
      'mpesaPhoneNumber': mpesaPhoneNumber,
      'mpesaPhoneAccountName': mpesaPhoneAccountName,
      'thankYouMessage': thankYouMessage,
    };
  }

  // Factory constructor to create PdfSettings from a Map (from JSON)
  factory PdfSettings.fromJson(Map<String, dynamic> json) {
    return PdfSettings(
      companyName: json['companyName'] as String? ?? 'Hempon Group',
      bankName: json['bankName'] as String? ?? 'KCB',
      bankAccountName: json['bankAccountName'] as String? ?? 'Magati Joel Omwoyo',
      bankAccountNumber: json['bankAccountNumber'] as String? ?? '1223534448',
      mpesaTillNumber: json['mpesaTillNumber'] as String? ?? '8804788',
      mpesaTillAccountName: json['mpesaTillAccountName'] as String? ?? 'Joel Omwoyo Magati',
      mpesaPhoneNumber: json['mpesaPhoneNumber'] as String? ?? '+254711879129',
      mpesaPhoneAccountName: json['mpesaPhoneAccountName'] as String? ?? 'Magati Joel',
      thankYouMessage: json['thankYouMessage'] as String? ?? 'Thank you for your business!',
    );
  }
}

