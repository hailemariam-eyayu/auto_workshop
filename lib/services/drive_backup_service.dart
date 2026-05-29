import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../db/database_helper.dart';

/// Handles Google Sign-In and Google Drive backup/restore.
///
/// Strategy:
///   • Uses the Drive `appDataFolder` scope — a hidden, private folder that
///     only this app can read/write. The user never sees it in their Drive UI.
///   • Backup file name: `auto_workshop_backup.json`
///   • On backup: dump all 6 tables to JSON → upload (create or update).
///   • On restore: download the file → wipe local DB → reimport all rows.
class DriveBackupService {
  static final DriveBackupService instance = DriveBackupService._();
  DriveBackupService._();

  static const _backupFileName = 'auto_workshop_backup.json';
  static const _appDataFolder = 'appDataFolder';

  final _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<GoogleSignInAccount?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return null;
    }
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      return _currentUser;
    } catch (e) {
      debugPrint('Silent sign-in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  Future<Map<String, String>?> _authHeaders() async {
    final user = _currentUser ?? await _googleSignIn.signInSilently();
    if (user == null) return null;
    _currentUser = user;
    final auth = await user.authentication;
    return {'Authorization': 'Bearer ${auth.accessToken}'};
  }

  // ── Export all data to JSON ───────────────────────────────────────────────

  Future<Map<String, dynamic>> _exportAllData() async {
    final db = await DatabaseHelper.instance.database;

    final employees      = await db.query('employees');
    final items          = await db.query('items');
    final borrows        = await db.query('borrows');
    final borrowHistory  = await db.query('borrow_history');
    final vehicles       = await db.query('vehicles');
    final services       = await db.query('services');

    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'employees':      employees,
      'items':          items,
      'borrows':        borrows,
      'borrow_history': borrowHistory,
      'vehicles':       vehicles,
      'services':       services,
    };
  }

  // ── Import JSON back into DB ──────────────────────────────────────────────

  Future<void> _importAllData(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      // Wipe in reverse FK order
      await txn.delete('services');
      await txn.delete('borrow_history');
      await txn.delete('borrows');
      await txn.delete('vehicles');
      await txn.delete('items');
      await txn.delete('employees');

      // Reimport
      for (final row in (data['employees'] as List? ?? [])) {
        await txn.insert('employees', Map<String, dynamic>.from(row));
      }
      for (final row in (data['items'] as List? ?? [])) {
        await txn.insert('items', Map<String, dynamic>.from(row));
      }
      for (final row in (data['borrows'] as List? ?? [])) {
        await txn.insert('borrows', Map<String, dynamic>.from(row));
      }
      for (final row in (data['borrow_history'] as List? ?? [])) {
        await txn.insert('borrow_history', Map<String, dynamic>.from(row));
      }
      for (final row in (data['vehicles'] as List? ?? [])) {
        await txn.insert('vehicles', Map<String, dynamic>.from(row));
      }
      for (final row in (data['services'] as List? ?? [])) {
        await txn.insert('services', Map<String, dynamic>.from(row));
      }
    });
  }

  // ── Drive helpers ─────────────────────────────────────────────────────────

  /// Returns the Drive file ID of the existing backup, or null.
  Future<String?> _findBackupFileId(Map<String, String> headers) async {
    final uri = Uri.parse(
      'https://www.googleapis.com/drive/v3/files'
      '?spaces=$_appDataFolder'
      '&q=name%3D%27$_backupFileName%27'
      '&fields=files(id)',
    );
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) return null;
    final files = (jsonDecode(resp.body)['files'] as List?) ?? [];
    if (files.isEmpty) return null;
    return files.first['id'] as String?;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Upload current DB to Drive. Returns true on success.
  Future<BackupResult> backup() async {
    final headers = await _authHeaders();
    if (headers == null) return BackupResult.notSignedIn;

    try {
      final data = await _exportAllData();
      final body = utf8.encode(jsonEncode(data));

      final existingId = await _findBackupFileId(headers);

      http.Response resp;
      if (existingId != null) {
        // PATCH — update existing file content
        resp = await http.patch(
          Uri.parse(
            'https://www.googleapis.com/upload/drive/v3/files/$existingId'
            '?uploadType=media',
          ),
          headers: {
            ...headers,
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: body,
        );
      } else {
        // POST — create new file in appDataFolder
        // Multipart: metadata + media
        final boundary = '-------314159265358979323846';
        final metaJson = jsonEncode({
          'name': _backupFileName,
          'parents': [_appDataFolder],
        });
        final multipart = '--$boundary\r\n'
            'Content-Type: application/json; charset=UTF-8\r\n\r\n'
            '$metaJson\r\n'
            '--$boundary\r\n'
            'Content-Type: application/json; charset=utf-8\r\n\r\n'
            '${utf8.decode(body)}\r\n'
            '--$boundary--';

        resp = await http.post(
          Uri.parse(
            'https://www.googleapis.com/upload/drive/v3/files'
            '?uploadType=multipart',
          ),
          headers: {
            ...headers,
            'Content-Type': 'multipart/related; boundary="$boundary"',
          },
          body: utf8.encode(multipart),
        );
      }

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return BackupResult.success;
      }
      debugPrint('Drive backup failed: ${resp.statusCode} ${resp.body}');
      return BackupResult.error;
    } catch (e) {
      debugPrint('Drive backup exception: $e');
      return BackupResult.error;
    }
  }

  /// Download backup from Drive and restore into local DB.
  Future<RestoreResult> restore() async {
    final headers = await _authHeaders();
    if (headers == null) return RestoreResult.notSignedIn;

    try {
      final fileId = await _findBackupFileId(headers);
      if (fileId == null) return RestoreResult.noBackupFound;

      final resp = await http.get(
        Uri.parse(
          'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
        ),
        headers: headers,
      );

      if (resp.statusCode != 200) {
        debugPrint('Drive restore failed: ${resp.statusCode}');
        return RestoreResult.error;
      }

      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      await _importAllData(data);
      return RestoreResult.success;
    } catch (e) {
      debugPrint('Drive restore exception: $e');
      return RestoreResult.error;
    }
  }

  /// Returns the ISO timestamp of the last backup, or null.
  Future<String?> getLastBackupTime() async {
    final headers = await _authHeaders();
    if (headers == null) return null;
    try {
      final uri = Uri.parse(
        'https://www.googleapis.com/drive/v3/files'
        '?spaces=$_appDataFolder'
        '&q=name%3D%27$_backupFileName%27'
        '&fields=files(id,modifiedTime)',
      );
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode != 200) return null;
      final files = (jsonDecode(resp.body)['files'] as List?) ?? [];
      if (files.isEmpty) return null;
      return files.first['modifiedTime'] as String?;
    } catch (_) {
      return null;
    }
  }
}

enum BackupResult { success, notSignedIn, error }
enum RestoreResult { success, notSignedIn, noBackupFound, error }
