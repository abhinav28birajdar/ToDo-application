import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BackupService {
  static const String _backupFileName = 'todo_backup.json';
  static const String _backupFolder = 'backups';

  // Create a backup of all app data
  static Future<String> createBackup({
    required Map<String, dynamic> todos,
    required Map<String, dynamic> categories,
    required Map<String, dynamic> settings,
  }) async {
    try {
      final backupData = {
        'version': '1.0.0',
        'created': DateTime.now().toIso8601String(),
        'appName': dotenv.env['APP_NAME'] ?? 'Flutter Todo App',
        'appVersion': dotenv.env['APP_VERSION'] ?? '1.0.0',
        'data': {
          'todos': todos,
          'categories': categories,
          'settings': settings,
        },
        'metadata': {
          'totalTodos': todos['todosCount'] ?? 0,
          'totalCategories': categories['categoriesCount'] ?? 0,
          'devicePlatform': Platform.operatingSystem,
          'backupType': 'full',
        }
      };

      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/$_backupFolder');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'backup_$timestamp.json';
      final file = File('${backupDir.path}/$fileName');

      final jsonString = json.encode(backupData);
      await file.writeAsString(jsonString);

      // Clean up old backups
      await _cleanupOldBackups(backupDir);

      debugPrint('Backup created successfully: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      rethrow;
    }
  }

  // Create an automatic backup
  static Future<void> createAutoBackup({
    required Map<String, dynamic> todos,
    required Map<String, dynamic> categories,
    required Map<String, dynamic> settings,
  }) async {
    try {
      final backupEnabled =
          dotenv.env['BACKUP_ENABLED']?.toLowerCase() == 'true';
      if (!backupEnabled) return;

      final intervalHours =
          int.tryParse(dotenv.env['BACKUP_INTERVAL_HOURS'] ?? '24') ?? 24;
      final lastBackupTime = await getLastBackupTime();

      if (lastBackupTime != null) {
        final timeSinceLastBackup = DateTime.now().difference(lastBackupTime);
        if (timeSinceLastBackup.inHours < intervalHours) {
          debugPrint('Auto backup skipped - too soon since last backup');
          return;
        }
      }

      await createBackup(
        todos: todos,
        categories: categories,
        settings: settings,
      );

      await _saveLastBackupTime();
    } catch (e) {
      debugPrint('Error creating auto backup: $e');
    }
  }

  // Restore data from a backup file
  static Future<Map<String, dynamic>> restoreFromBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      final jsonString = await file.readAsString();
      final backupData = json.decode(jsonString) as Map<String, dynamic>;

      // Validate backup structure
      if (!_validateBackupStructure(backupData)) {
        throw Exception('Invalid backup file format');
      }

      debugPrint('Backup restored successfully from: $filePath');
      return backupData['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      rethrow;
    }
  }

  // Get list of available backup files
  static Future<List<Map<String, dynamic>>> getAvailableBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/$_backupFolder');

      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      final backups = <Map<String, dynamic>>[];

      for (final file in files) {
        try {
          final stat = await file.stat();
          final fileName = file.path.split('/').last;

          // Try to read basic info from the backup
          final jsonString = await file.readAsString();
          final backupData = json.decode(jsonString) as Map<String, dynamic>;

          backups.add({
            'fileName': fileName,
            'filePath': file.path,
            'size': stat.size,
            'created': backupData['created'] ?? stat.modified.toIso8601String(),
            'version': backupData['version'] ?? 'Unknown',
            'todosCount': backupData['metadata']?['totalTodos'] ?? 0,
            'categoriesCount': backupData['metadata']?['totalCategories'] ?? 0,
            'backupType': backupData['metadata']?['backupType'] ?? 'unknown',
          });
        } catch (e) {
          debugPrint('Error reading backup file ${file.path}: $e');
        }
      }

      // Sort by creation date (newest first)
      backups.sort((a, b) =>
          DateTime.parse(b['created']).compareTo(DateTime.parse(a['created'])));

      return backups;
    } catch (e) {
      debugPrint('Error getting available backups: $e');
      return [];
    }
  }

  // Delete a backup file
  static Future<void> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Backup deleted: $filePath');
      }
    } catch (e) {
      debugPrint('Error deleting backup: $e');
      rethrow;
    }
  }

  // Export backup to external storage (for sharing)
  static Future<String> exportBackup(
      String backupPath, String exportPath) async {
    try {
      final sourceFile = File(backupPath);
      final targetFile = File(exportPath);

      await sourceFile.copy(targetFile.path);
      debugPrint('Backup exported to: $exportPath');

      return targetFile.path;
    } catch (e) {
      debugPrint('Error exporting backup: $e');
      rethrow;
    }
  }

  // Import backup from external source
  static Future<String> importBackup(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source backup file not found');
      }

      // Validate the backup before importing
      final jsonString = await sourceFile.readAsString();
      final backupData = json.decode(jsonString) as Map<String, dynamic>;

      if (!_validateBackupStructure(backupData)) {
        throw Exception('Invalid backup file format');
      }

      // Copy to app's backup directory
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/$_backupFolder');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'imported_backup_$timestamp.json';
      final targetFile = File('${backupDir.path}/$fileName');

      await sourceFile.copy(targetFile.path);
      debugPrint('Backup imported successfully: ${targetFile.path}');

      return targetFile.path;
    } catch (e) {
      debugPrint('Error importing backup: $e');
      rethrow;
    }
  }

  // Get backup statistics
  static Future<Map<String, dynamic>> getBackupStats() async {
    try {
      final backups = await getAvailableBackups();
      int totalSize = 0;

      for (final backup in backups) {
        totalSize += backup['size'] as int;
      }

      final lastBackup = backups.isNotEmpty ? backups.first : null;

      return {
        'totalBackups': backups.length,
        'totalSize': totalSize,
        'lastBackupDate': lastBackup?['created'],
        'oldestBackupDate': backups.isNotEmpty ? backups.last['created'] : null,
      };
    } catch (e) {
      debugPrint('Error getting backup stats: $e');
      return {
        'totalBackups': 0,
        'totalSize': 0,
        'lastBackupDate': null,
        'oldestBackupDate': null,
      };
    }
  }

  // Private helper methods
  static Future<void> _cleanupOldBackups(Directory backupDir) async {
    try {
      final maxBackups =
          int.tryParse(dotenv.env['MAX_BACKUP_FILES'] ?? '5') ?? 5;

      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      if (files.length <= maxBackups) return;

      // Sort by modification date (oldest first)
      files.sort(
          (a, b) => a.statSync().modified.compareTo(b.statSync().modified));

      // Delete oldest files
      final filesToDelete = files.take(files.length - maxBackups);
      for (final file in filesToDelete) {
        await file.delete();
        debugPrint('Old backup deleted: ${file.path}');
      }
    } catch (e) {
      debugPrint('Error cleaning up old backups: $e');
    }
  }

  static bool _validateBackupStructure(Map<String, dynamic> backupData) {
    try {
      return backupData.containsKey('version') &&
          backupData.containsKey('created') &&
          backupData.containsKey('data') &&
          backupData['data'] is Map<String, dynamic>;
    } catch (e) {
      return false;
    }
  }

  static Future<DateTime?> getLastBackupTime() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/last_backup_time.txt');

      if (await file.exists()) {
        final timeString = await file.readAsString();
        return DateTime.parse(timeString);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting last backup time: $e');
      return null;
    }
  }

  static Future<void> _saveLastBackupTime() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/last_backup_time.txt');
      await file.writeAsString(DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error saving last backup time: $e');
    }
  }
}
