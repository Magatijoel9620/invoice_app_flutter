class BusinessProfile {
  final String id;
  final String name;
  final String businessType;
  final String phone;
  final String email;
  final String address;
  final String kraPin;
  final String currency;
  final String invoicePrefix;
  final int nextInvoiceNumber;
  final int defaultDueDays;
  final bool vatRegistered;
  final double vatRate;
  final String logoPath;
  final String thankYouMessage;
  final String mpesaTill;
  final String paybill;
  final String bankName;
  final String bankAccount;
  final DateTime updatedAt;

  BusinessProfile({
    required this.id,
    required this.name,
    required this.businessType,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.kraPin = '',
    this.currency = 'KES',
    this.invoicePrefix = 'INV',
    this.nextInvoiceNumber = 1,
    this.defaultDueDays = 14,
    this.vatRegistered = false,
    this.vatRate = 16,
    this.logoPath = '',
    this.thankYouMessage = 'Thank you for your business!',
    this.mpesaTill = '',
    this.paybill = '',
    this.bankName = '',
    this.bankAccount = '',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime(2000, 1, 1);

  BusinessProfile copyWith({
    String? id,
    String? name,
    String? businessType,
    String? phone,
    String? email,
    String? address,
    String? kraPin,
    String? currency,
    String? invoicePrefix,
    int? nextInvoiceNumber,
    int? defaultDueDays,
    bool? vatRegistered,
    double? vatRate,
    String? logoPath,
    String? thankYouMessage,
    String? mpesaTill,
    String? paybill,
    String? bankName,
    String? bankAccount,
    DateTime? updatedAt,
  }) => BusinessProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    businessType: businessType ?? this.businessType,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    kraPin: kraPin ?? this.kraPin,
    currency: currency ?? this.currency,
    invoicePrefix: invoicePrefix ?? this.invoicePrefix,
    nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
    defaultDueDays: defaultDueDays ?? this.defaultDueDays,
    vatRegistered: vatRegistered ?? this.vatRegistered,
    vatRate: vatRate ?? this.vatRate,
    logoPath: logoPath ?? this.logoPath,
    thankYouMessage: thankYouMessage ?? this.thankYouMessage,
    mpesaTill: mpesaTill ?? this.mpesaTill,
    paybill: paybill ?? this.paybill,
    bankName: bankName ?? this.bankName,
    bankAccount: bankAccount ?? this.bankAccount,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'businessType': businessType,
        'phone': phone,
        'email': email,
        'address': address,
        'kraPin': kraPin,
        'currency': currency,
        'invoicePrefix': invoicePrefix,
        'nextInvoiceNumber': nextInvoiceNumber,
        'defaultDueDays': defaultDueDays,
        'vatRegistered': vatRegistered,
        'vatRate': vatRate,
        'logoPath': logoPath,
        'thankYouMessage': thankYouMessage,
        'mpesaTill': mpesaTill,
        'paybill': paybill,
        'bankName': bankName,
        'bankAccount': bankAccount,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory BusinessProfile.fromJson(Map<String, dynamic> json) => BusinessProfile(
        id: json['id']?.toString() ?? 'default',
        name: json['name']?.toString() ?? 'My Business',
        businessType: json['businessType']?.toString() ?? 'Other',
        phone: json['phone']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        kraPin: json['kraPin']?.toString() ?? '',
        currency: json['currency']?.toString() ?? 'KES',
        invoicePrefix: json['invoicePrefix']?.toString() ?? 'INV',
        nextInvoiceNumber: (json['nextInvoiceNumber'] as num?)?.toInt() ?? 1,
        defaultDueDays: (json['defaultDueDays'] as num?)?.toInt() ?? 14,
        vatRegistered: json['vatRegistered'] as bool? ?? false,
        vatRate: (json['vatRate'] as num?)?.toDouble() ?? 16,
        logoPath: json['logoPath']?.toString() ?? '',
        thankYouMessage: json['thankYouMessage']?.toString() ?? 'Thank you for your business!',
        mpesaTill: json['mpesaTill']?.toString() ?? '',
        paybill: json['paybill']?.toString() ?? '',
        bankName: json['bankName']?.toString() ?? '',
        bankAccount: json['bankAccount']?.toString() ?? '',
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime(2000, 1, 1),
      );
}
