import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/business_profile.dart';
import '../providers/app_providers.dart';
import 'widgets/app_card.dart';

class BusinessSettingsScreen extends ConsumerStatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  ConsumerState<BusinessSettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<BusinessSettingsScreen> {
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController email;
  late final TextEditingController address;
  late final TextEditingController pin;
  late final TextEditingController prefix;
  late final TextEditingController mpesa;
  late final TextEditingController paybill;
  late final TextEditingController bank;
  late final TextEditingController account;
  late final TextEditingController thanks;
  late final TextEditingController currency;

  bool vat = false;
  double rate = 16;
  int due = 14;
  String logoPath = '';

  static const dueOptions = [0, 7, 14, 30, 60];

  @override
  void initState() {
    super.initState();
    final business = ref.read(businessProvider).valueOrNull ??
        BusinessProfile(
          id: 'default',
          name: 'My Business',
          businessType: 'Other',
        );

    name = TextEditingController(text: business.name);
    phone = TextEditingController(text: business.phone);
    email = TextEditingController(text: business.email);
    address = TextEditingController(text: business.address);
    pin = TextEditingController(text: business.kraPin);
    prefix = TextEditingController(text: business.invoicePrefix);
    mpesa = TextEditingController(text: business.mpesaTill);
    paybill = TextEditingController(text: business.paybill);
    bank = TextEditingController(text: business.bankName);
    account = TextEditingController(text: business.bankAccount);
    thanks = TextEditingController(text: business.thankYouMessage);
    currency = TextEditingController(text: business.currency);

    vat = business.vatRegistered;
    rate = business.vatRate.clamp(0, 30).toDouble();
    logoPath = business.logoPath;
    due = dueOptions.contains(business.defaultDueDays)
        ? business.defaultDueDays
        : 14;
  }

  @override
  void dispose() {
    for (final controller in [
      name,
      phone,
      email,
      address,
      pin,
      prefix,
      mpesa,
      paybill,
      bank,
      account,
      thanks,
      currency,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }


  String get _logoStatus {
    if (logoPath.isEmpty) return 'No logo selected. PDF will use text branding.';
    return 'Logo selected: ${logoPath.split(RegExp(r'[\\/]')).last}';
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    final path = result?.files.single.path;
    if (path != null && mounted) setState(() => logoPath = path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business settings'),
        actions: [
          IconButton(
            tooltip: 'Save settings',
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
        children: [
          Text(
            'Business identity',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'These details appear on invoices and receipts.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Business name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: address,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pin,
                  decoration: const InputDecoration(labelText: 'KRA PIN (optional)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Branding & currency',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: currency,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Currency code',
                    hintText: 'KES',
                  ),
                  maxLength: 3,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _logoStatus,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickLogo,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Choose logo'),
                    ),
                    if (logoPath.isNotEmpty)
                      IconButton(
                        tooltip: 'Remove logo',
                        onPressed: () => setState(() => logoPath = ''),
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice defaults',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: prefix,
                        decoration:
                            const InputDecoration(labelText: 'Invoice prefix'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: due,
                        decoration:
                            const InputDecoration(labelText: 'Default due'),
                        items: dueOptions
                            .map(
                              (days) => DropdownMenuItem<int>(
                                value: days,
                                child: Text(
                                  days == 0 ? 'Due today' : '$days days',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => due = value);
                        },
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('VAT registered'),
                  subtitle: const Text('Apply VAT to taxable invoice items'),
                  value: vat,
                  onChanged: (value) => setState(() => vat = value),
                ),
                if (vat)
                  Slider(
                    value: rate,
                    min: 0,
                    max: 30,
                    divisions: 30,
                    label: '${rate.toStringAsFixed(0)}%',
                    onChanged: (value) => setState(() => rate = value),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment details',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mpesa,
                  decoration: const InputDecoration(labelText: 'M-Pesa Till'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: paybill,
                  decoration: const InputDecoration(labelText: 'Paybill'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: bank,
                        decoration: const InputDecoration(labelText: 'Bank'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: account,
                        decoration: const InputDecoration(labelText: 'Account'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice footer',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: thanks,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'Thank-you message'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Save settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final old = ref.read(businessProvider).valueOrNull ??
        BusinessProfile(
          id: 'default',
          name: 'My Business',
          businessType: 'Other',
        );

    await ref.read(businessProvider.notifier).save(
          old.copyWith(
            name: name.text.trim().isEmpty ? 'My Business' : name.text.trim(),
            phone: phone.text.trim(),
            email: email.text.trim(),
            address: address.text.trim(),
            kraPin: pin.text.trim(),
            currency: currency.text.trim().isEmpty
                ? 'KES'
                : currency.text.trim().toUpperCase(), 
            invoicePrefix: prefix.text.trim().isEmpty
                ? 'INV'
                : prefix.text.trim().toUpperCase(),
            defaultDueDays: due,
            vatRegistered: vat,
            vatRate: rate,
            mpesaTill: mpesa.text.trim(),
            paybill: paybill.text.trim(),
            bankName: bank.text.trim(),
            bankAccount: account.text.trim(),
            logoPath: logoPath,
            thankYouMessage: thanks.text.trim().isEmpty
                ? 'Thank you for your business!'
                : thanks.text.trim(),
          ),
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Business settings saved')),
    );
    Navigator.pop(context);
  }
}
