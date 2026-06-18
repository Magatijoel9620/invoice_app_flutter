// lib/screens/pdf_settings_screen.dart
import 'package:flutter/material.dart';
import '../models/pdf_settings.dart';
import '../services/pdf_settings_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
class PdfSettingsScreen extends StatefulWidget {
  const PdfSettingsScreen({super.key});

  @override
  State<PdfSettingsScreen> createState() => _PdfSettingsScreenState();
}

class _PdfSettingsScreenState extends State<PdfSettingsScreen> {
  String? _logoPath;
  final _formKey = GlobalKey<FormState>();
  final PdfSettingsService _settingsService = PdfSettingsService();
  late Future<PdfSettings> _settingsFuture;
  PdfSettings _currentSettings = PdfSettings(); // Initialize with defaults

  // Text editing controllers
  final _companyNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _mpesaTillNumberController = TextEditingController();
  final _mpesaTillAccountNameController = TextEditingController();
  final _mpesaPhoneNumberController = TextEditingController();
  final _mpesaPhoneAccountNameController = TextEditingController();
  final _thankYouMessageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    _settingsFuture = _loadAndSetSettings();
  }
  Future<void> pickLogo() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      setState(() {
        _logoPath = image.path;
      });
    }
  }
  Future<PdfSettings> _loadAndSetSettings() async {
    final settings = await _settingsService.loadSettings();
    setState(() {
      _currentSettings = settings;
      _logoPath = settings.logoPath;
      _companyNameController.text = _currentSettings.companyName;
      _bankNameController.text = _currentSettings.bankName;
      _bankAccountNameController.text = _currentSettings.bankAccountName;
      _bankAccountNumberController.text = _currentSettings.bankAccountNumber;
      _mpesaTillNumberController.text = _currentSettings.mpesaTillNumber;
      _mpesaTillAccountNameController.text = _currentSettings.mpesaTillAccountName;
      _mpesaPhoneNumberController.text = _currentSettings.mpesaPhoneNumber;
      _mpesaPhoneAccountNameController.text = _currentSettings.mpesaPhoneAccountName;
      _thankYouMessageController.text = _currentSettings.thankYouMessage;
    });
    return settings;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _bankNameController.dispose();
    _bankAccountNameController.dispose();
    _bankAccountNumberController.dispose();
    _mpesaTillNumberController.dispose();
    _mpesaTillAccountNameController.dispose();
    _mpesaPhoneNumberController.dispose();
    _mpesaPhoneAccountNameController.dispose();
    _thankYouMessageController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save(); // Triggers onSaved for TextFormFields

      final updatedSettings = PdfSettings(
        companyName: _companyNameController.text.trim(),
        bankName: _bankNameController.text.trim(),
        bankAccountName: _bankAccountNameController.text.trim(),
        bankAccountNumber: _bankAccountNumberController.text.trim(),
        mpesaTillNumber: _mpesaTillNumberController.text.trim(),
        mpesaTillAccountName: _mpesaTillAccountNameController.text.trim(),
        mpesaPhoneNumber: _mpesaPhoneNumberController.text.trim(),
        mpesaPhoneAccountName: _mpesaPhoneAccountNameController.text.trim(),
        thankYouMessage: _thankYouMessageController.text.trim(),
        logoPath: _logoPath,
      );

      await _settingsService.saveSettings(updatedSettings);
      setState(() {
        _currentSettings = updatedSettings; // Update local state if needed
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF Settings saved successfully!')),
        );
        Navigator.of(context).pop(); // Go back after saving
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText + (isOptional ? ' (Optional)' : ''),
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        validator: (value) {
          if (!isOptional && (value == null || value.trim().isEmpty)) {
            return 'Please enter $labelText';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Customization Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: FutureBuilder<PdfSettings>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading settings: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No settings found.'));
          }

          // Settings loaded, build the form
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: <Widget>[
                Text('Company & General', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: pickLogo,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: _logoPath != null
                              ? Image.file(File(_logoPath!), fit: BoxFit.cover)
                              : (_currentSettings.logoPath != null
                              ? Image.file(File(_currentSettings.logoPath!))
                              : const Icon(Icons.image)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Tap to upload company logo"),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _buildTextField(
                  controller: _companyNameController,
                  labelText: 'Company Name',
                ),
                _buildTextField(
                  controller: _thankYouMessageController,
                  labelText: 'Thank You Message',
                ),
                const SizedBox(height: 20),
                Text('Bank Payment Details', style: Theme.of(context).textTheme.titleLarge),
                _buildTextField(
                  controller: _bankNameController,
                  labelText: 'Bank Name',
                ),
                _buildTextField(
                  controller: _bankAccountNameController,
                  labelText: 'Bank Account Name',
                ),
                _buildTextField(
                  controller: _bankAccountNumberController,
                  labelText: 'Bank Account Number',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                Text('M-Pesa Till Details', style: Theme.of(context).textTheme.titleLarge),
                _buildTextField(
                  controller: _mpesaTillNumberController,
                  labelText: 'M-Pesa Till Number',
                  keyboardType: TextInputType.number,
                  isOptional: true,
                ),
                _buildTextField(
                  controller: _mpesaTillAccountNameController,
                  labelText: 'M-Pesa Till Account Name',
                  isOptional: true,
                ),
                const SizedBox(height: 20),
                Text('M-Pesa Phone (Paybill/Personal)', style: Theme.of(context).textTheme.titleLarge),
                _buildTextField(
                  controller: _mpesaPhoneNumberController,
                  labelText: 'M-Pesa Phone Number',
                  keyboardType: TextInputType.phone,
                  isOptional: true,
                ),
                _buildTextField(
                  controller: _mpesaPhoneAccountNameController,
                  labelText: 'M-Pesa Phone Account Name',
                  isOptional: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Settings'),
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

