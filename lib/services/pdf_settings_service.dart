// lib/services/pdf_settings_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pdf_settings.dart';

class PdfSettingsService {
  static const String _settingsKey = 'pdf_settings';

  Future<void> saveSettings(PdfSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, jsonString);
  }

  Future<PdfSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_settingsKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        return PdfSettings.fromJson(jsonMap);
      } catch (e) {
        // Handle potential decoding error, maybe return default settings
        print('Error decoding PDF settings: $e');
        return PdfSettings(); // Return default if decoding fails
      }
    }
    return PdfSettings(); // Return default if no settings saved yet
  }
}

