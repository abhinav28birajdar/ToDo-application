import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:share_plus/share_plus.dart';

import '../models/task.dart';
import '../models/note.dart';
import '../models/category.dart';
import '../models/app_settings.dart';
import 'supabase/supabase_service.dart';

class BackupService {
  static const String _backupFileName = 'pro_organizer_backup.json';
  static const String _backupFolder = 'backups';

  final SupabaseService? _supabaseService;

  BackupService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService;

  // Create a backup of all app data
  Future<String> createBackup({
    required List<Task> tasks,
    required List<Note> notes,
    required List<Category> categories,
    required AppSettings settings,
  }) async {
    try {
      final backupData = {
        'version': '2.0.0',
        'created': DateTime.now().toIso8601String(),
        'appName': dotenv.env['APP_NAME'] ?? 'Pro-Organizer',
        'appVersion': dotenv.env['APP_VERSION'] ?? '1.0.0',
        'data': {
          'tasks': tasks.map((task) => task.toJson()).toList(),
          'notes': notes.map((note) => note.toJson()).toList(),
          'categories':
              categories.map((category) => category.toJson()).toList(),
          'settings': settings.toJson(),
        },
        'metadata': {
          'totalTasks': tasks.length,
          'totalNotes': notes.length,
          'totalCategories': categories.length,
          'devicePlatform': Platform.operatingSystem,
          'backupType': 'full',
          'userId': _supabaseService?.currentUser?.id
        }
      };

      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/$_backupFolder');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'pro_organizer_backup_$timestamp.json';
      final file = File('${backupDir.path}/$fileName');

      final jsonString = json.encode(backupData);
      await file.writeAsString(jsonString);

      // Clean up old backups
      await _cleanupOldBackups(backupDir);

      // Also backup to Supabase if available and authenticated
      if (_supabaseService != null && _supabaseService!.isSignedIn) {
        await _backupToSupabase(
          tasks: tasks,
          notes: notes,
          categories: categories,
          settings: settings,
        );
      }

      debugPrint('Backup created successfully: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      rethrow;
    }
  }

  // Backup to Supabase cloud
  Future<void> _backupToSupabase({
    required List<Task> tasks,
    required List<Note> notes,
    required List<Category> categories,
    required AppSettings settings,
  }) async {
    try {
      // Check if Supabase service is available and user is authenticated
      if (_supabaseService == null || !_supabaseService!.isSignedIn) {
        debugPrint('Skipping Supabase backup - not authenticated');
        return;
      }

      final userId = _supabaseService!.currentUser!.id;

      // Create a backup record
      final backupRecord = {
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'metadata': {
          'totalTasks': tasks.length,
          'totalNotes': notes.length,
          'totalCategories': categories.length,
          'devicePlatform': Platform.operatingSystem,
        },
        'data': {
          'tasks': tasks.map((task) => task.toSupabase()).toList(),
          'notes': notes.map((note) => note.toSupabase()).toList(),
          'categories':
              categories.map((category) => category.toSupabase()).toList(),
          'settings': settings.toSupabase(),
        }
      };

      // Insert into backups table
      await SupabaseService.client.from('backups').insert(backupRecord);

      debugPrint('Backup to Supabase completed successfully');
    } catch (e) {
      debugPrint('Error backing up to Supabase: $e');
    }
  }

  // Create an automatic backup
  Future<void> createAutoBackup({
    required List<Task> tasks,
    required List<Note> notes,
    required List<Category> categories,
    required AppSettings settings,
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
        tasks: tasks,
        notes: notes,
        categories: categories,
        settings: settings,
      );

      await _saveLastBackupTime();
    } catch (e) {
      debugPrint('Error creating auto backup: $e');
    }
  }

  // Restore data from a backup file
  Future<Map<String, dynamic>> restoreFromBackup(String filePath) async {
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
  Future<List<Map<String, dynamic>>> getAvailableBackups() async {
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
  Future<void> deleteBackup(String filePath) async {
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
  Future<String> exportBackup(String backupPath, String exportPath) async {
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
  Future<String> importBackup(String sourcePath) async {
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
  Future<Map<String, dynamic>> getBackupStats() async {
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
  Future<void> _cleanupOldBackups(Directory backupDir) async {
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

  bool _validateBackupStructure(Map<String, dynamic> backupData) {
    try {
      return backupData.containsKey('version') &&
          backupData.containsKey('created') &&
          backupData.containsKey('data') &&
          backupData['data'] is Map<String, dynamic>;
    } catch (e) {
      return false;
    }
  }

  Future<DateTime?> getLastBackupTime() async {
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

  Future<void> _saveLastBackupTime() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/last_backup_time.txt');
      await file.writeAsString(DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error saving last backup time: $e');
    }
  }

  // Restore data from Supabase cloud backup
  Future<Map<String, dynamic>> restoreFromSupabase() async {
    try {
      // Check if Supabase service is available and user is authenticated
      if (_supabaseService == null || !_supabaseService!.isSignedIn) {
        throw Exception(
            'You must be signed in to restore data from cloud backup.');
      }

      final userId = _supabaseService!.currentUser!.id;

      // Get the latest backup
      final Map<String, dynamic> response;

      try {
        response = await SupabaseService.client
            .from('backups')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .single();
      } catch (e) {
        throw Exception('No backup found in the cloud: $e');
      }

      final backupData = response['data'] as Map<String, dynamic>;

      // Parse tasks
      final tasksData = backupData['tasks'] as List;
      final tasks =
          tasksData.map((taskMap) => Task.fromSupabase(taskMap)).toList();

      // Parse notes
      final notesData = backupData['notes'] as List;
      final notes =
          notesData.map((noteMap) => Note.fromSupabase(noteMap)).toList();

      // Parse categories
      final categoriesData = backupData['categories'] as List;
      final categories = categoriesData
          .map((categoryMap) => Category.fromSupabase(categoryMap))
          .toList();

      // Parse settings
      final settingsData = backupData['settings'] as Map<String, dynamic>;
      final settings = AppSettings.fromSupabase(settingsData);

      return {
        'tasks': tasks,
        'notes': notes,
        'categories': categories,
        'settings': settings,
      };
    } catch (e) {
      debugPrint('Error restoring from Supabase: $e');
      rethrow;
    }
  }

  // Share a backup file using the share_plus package
  Future<void> shareBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      await Share.shareXFiles(
        [XFile(backupPath)],
        subject: 'Pro-Organizer Backup',
        text: 'Here is my Pro-Organizer data backup from ${DateTime.now()}',
      );

      debugPrint('Backup shared successfully: $backupPath');
    } catch (e) {
      debugPrint('Error sharing backup: $e');
      rethrow;
    }
  }
}
