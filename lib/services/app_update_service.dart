import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    this.releaseNotes,
  });

  final String latestVersion;
  final String downloadUrl;
  final String? releaseNotes;
}

class AppUpdateService {
  AppUpdateService._();

  static final instance = AppUpdateService._();

  /// Publish InvoiceEasy's update metadata at this URL.
  /// Keep this separate from Farmora's update.json endpoint.
  static const updateInfoUrl =
      'https://portfolio.hempongroup.co.ke/invoice-easy/update.json';

  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(
            Uri.parse(updateInfoUrl),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint(
          'InvoiceEasy update check returned HTTP ${response.statusCode}.',
        );
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('InvoiceEasy update metadata has an invalid format.');
        return null;
      }

      final latestVersion = decoded['version']?.toString().trim();
      final downloadUrl = decoded['downloadUrl']?.toString().trim();
      final releaseNotes = decoded['releaseNotes']?.toString().trim();

      if (latestVersion == null ||
          latestVersion.isEmpty ||
          downloadUrl == null ||
          downloadUrl.isEmpty) {
        debugPrint('InvoiceEasy update metadata is missing required fields.');
        return null;
      }

      final downloadUri = Uri.tryParse(downloadUrl);
      if (downloadUri == null ||
          downloadUri.scheme != 'https' ||
          downloadUri.host.isEmpty) {
        debugPrint(
          'InvoiceEasy update metadata contains an invalid download URL.',
        );
        return null;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      if (!_isNewerVersion(latestVersion, packageInfo.version)) {
        return null;
      }

      return AppUpdateInfo(
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes == null || releaseNotes.isEmpty
            ? null
            : releaseNotes,
      );
    } catch (error) {
      // Do not expose server details or interrupt normal app usage.
      debugPrint('InvoiceEasy update check failed: ${error.runtimeType}');
      return null;
    }
  }

  Future<bool> openDownloadPage(String downloadUrl) async {
    final uri = Uri.tryParse(downloadUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return false;
    }

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  bool _isNewerVersion(String latest, String current) {
    final latestParts = _versionParts(latest);
    final currentParts = _versionParts(current);

    if (latestParts == null || currentParts == null) {
      return false;
    }

    while (latestParts.length < 3) {
      latestParts.add(0);
    }
    while (currentParts.length < 3) {
      currentParts.add(0);
    }

    for (var i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  List<int>? _versionParts(String version) {
    final normalized = version.trim().split('+').first;
    final parts = normalized.split('.');
    if (parts.isEmpty || parts.length > 3) return null;

    final parsed = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0) return null;
      parsed.add(value);
    }
    return parsed;
  }
}
