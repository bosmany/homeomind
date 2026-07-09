// backup_service.dart
// HomeoMind — takes the Uint8List from DatabaseHelper.exportBackupZip()
// and delivers it to the user: browser download on web (PWA), share sheet
// on Android/iOS. Wire this to the 'Backup Data' button.
//
// pubspec.yaml dependencies:
//   file_saver: ^0.2.9      # cross-platform save/download, no dart:html needed
//
// (Alternative on mobile only: path_provider + share_plus.)

import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

import 'db_helper.dart';

class BackupService {
  BackupService._();

  /// Exports all cases and triggers a download/save of
  /// `homeomind_backup_YYYY-MM-DD.zip`. Returns the saved path/filename.
  static Future<String> backupAllCases() async {
    final Uint8List zipBytes = await DatabaseHelper.instance.exportBackupZip();

    final stamp = DateTime.now().toIso8601String().split('T').first;
    try {
      final result = await FileSaver.instance.saveFile(
        name: 'homeomind_backup_$stamp',
        bytes: zipBytes,
        ext: 'zip',
        mimeType: MimeType.zip,
      );
      // Some platforms return null/empty on silent failure — surface it
      // clearly instead of letting a null propagate ("unsupported result").
      if (result.isEmpty) {
        throw StateError('Save returned no path — check storage permissions.');
      }
      return result;
    } catch (e) {
      throw Exception('Backup failed: $e');
    }
  }
}

/* Usage in UI (e.g. ui_dashboard.dart):

FilledButton.icon(
  icon: const Icon(Icons.archive_outlined),
  label: const Text('Backup Data'),
  onPressed: () async {
    final path = await BackupService.backupAllCases();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup saved: $path')),
      );
    }
  },
),
*/
