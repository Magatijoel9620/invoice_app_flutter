class PdfSettings {
  // =========================
  // COMPANY INFO
  // =========================
  String companyName;
  String companyAddress;
  String companyEmail;
  String companyPhone;
  String kraPin;

  // LOGO (NEW - for PDF branding)
  String? logoPath;

  // =========================
  // BANK DETAILS
  // =========================
  String bankName;
  String bankAccountName;
  String bankAccountNumber;

  // =========================
  // M-PESA DETAILS
  // =========================
  String mpesaTillNumber;
  String mpesaTillAccountName;
  String mpesaPhoneNumber;
  String mpesaPhoneAccountName;

  // =========================
  // FOOTER
  // =========================
  String thankYouMessage;

  PdfSettings({
    this.companyName = 'Hempon Group',
    this.companyAddress = 'Mombasa, Kenya',
    this.companyEmail = 'info@hempongroup.co.ke',
    this.companyPhone = '+254738219953',
    this.kraPin = '',

    this.logoPath,

    this.bankName = 'KCB',
    this.bankAccountName = 'MAGATI JOEL',
    this.bankAccountNumber = '1223534448',

    this.mpesaTillNumber = '8804788',
    this.mpesaTillAccountName = 'JOEL OMWOYO',
    this.mpesaPhoneNumber = '+254711879129',
    this.mpesaPhoneAccountName = 'MAGATI JOEL',

    this.thankYouMessage = 'Thank you for your business!',
  });

  // =========================
  // TO JSON
  // =========================
  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyEmail': companyEmail,
      'companyPhone': companyPhone,
      'kraPin': kraPin,
      'logoPath': logoPath,
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

  // =========================
  // FROM JSON
  // =========================
  factory PdfSettings.fromJson(Map<String, dynamic> json) {
    return PdfSettings(
      companyName: json['companyName'] as String? ?? 'Hempon Group',
      companyAddress: json['companyAddress'] as String? ?? 'Mombasa, Kenya',
      companyEmail: json['companyEmail'] as String? ?? 'info@hempongroup.co.ke',
      companyPhone: json['companyPhone'] as String? ?? '+254738219953',
      kraPin: json['kraPin'] as String? ?? '',

      logoPath: json['logoPath'] as String?,

      bankName: json['bankName'] as String? ?? 'KCB',
      bankAccountName: json['bankAccountName'] as String? ?? 'MAGATI JOEL',
      bankAccountNumber: json['bankAccountNumber'] as String? ?? '1223534448',

      mpesaTillNumber: json['mpesaTillNumber'] as String? ?? '8804788',
      mpesaTillAccountName: json['mpesaTillAccountName'] as String? ?? 'JOEL OMWOYO',
      mpesaPhoneNumber: json['mpesaPhoneNumber'] as String? ?? '+254711879129',
      mpesaPhoneAccountName: json['mpesaPhoneAccountName'] as String? ?? 'MAGATI JOEL',

      thankYouMessage: json['thankYouMessage'] as String? ?? 'Thank you for your business!',
    );
  }
}