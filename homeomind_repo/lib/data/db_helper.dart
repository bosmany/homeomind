// db_helper.dart
// HomeoMind — singleton SQLite helper (sqflite) with CRUD + zip export.
//
// PWA NOTE: plain `sqflite` does NOT run on Flutter Web. This helper switches
// to `sqflite_common_ffi_web` (WASM + IndexedDB) when kIsWeb is true, so the
// same code works on Android/iOS/desktop AND as a PWA.
//
// pubspec.yaml dependencies:
//   sqflite: ^2.3.0
//   sqflite_common_ffi_web: ^0.4.0
//   archive: ^3.4.0
//   path: ^1.9.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/case_model.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'homeomind.db';
  static const _dbVersion = 1;
  static const _table = 'cases';

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final DatabaseFactory factory =
        kIsWeb ? databaseFactoryFfiWeb : databaseFactory;
    final dbPath = kIsWeb
        ? _dbName // web: virtual path inside IndexedDB
        : p.join(await factory.getDatabasesPath(), _dbName);

    return factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_table (
              id           INTEGER PRIMARY KEY AUTOINCREMENT,
              case_no      TEXT UNIQUE,
              patient_name TEXT,
              case_date    TEXT,
              payload      TEXT NOT NULL,
              created_at   TEXT,
              updated_at   TEXT
            )
          ''');
          await db.execute(
              'CREATE INDEX idx_cases_name ON $_table (patient_name)');
          await db.execute(
              'CREATE INDEX idx_cases_date ON $_table (case_date)');
        },
        // onUpgrade: reserved for future schema migrations.
      ),
    );
  }

  // ---------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------

  Future<int> insertCase(HomeoCase c) async {
    final db = await database;
    c.updatedAt = DateTime.now().toIso8601String();
    final id = await db.insert(_table, c.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
    c.id = id;
    // Re-write payload so the embedded JSON also carries the assigned id.
    await db.update(_table, {'payload': jsonEncode(c.toJson())},
        where: 'id = ?', whereArgs: [id]);
    return id;
  }

  Future<HomeoCase?> getCase(int id) async {
    final db = await database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : HomeoCase.fromDbMap(rows.first);
  }

  /// Newest first; optional name/caseNo search for the dashboard list.
  Future<List<HomeoCase>> getAllCases({String? search}) async {
    final db = await database;
    final rows = await db.query(
      _table,
      where: search != null && search.trim().isNotEmpty
          ? 'patient_name LIKE ? OR case_no LIKE ?'
          : null,
      whereArgs: search != null && search.trim().isNotEmpty
          ? ['%$search%', '%$search%']
          : null,
      orderBy: 'case_date DESC',
    );
    return rows
        .map((r) {
          try {
            return HomeoCase.fromDbMap(r);
          } catch (_) {
            return null; // corrupt/legacy row — skip it, never crash the list
          }
        })
        .whereType<HomeoCase>()
        .toList();
  }

  Future<int> updateCase(HomeoCase c) async {
    assert(c.id != null, 'Cannot update a case without an id');
    final db = await database;
    c.updatedAt = DateTime.now().toIso8601String();
    return db.update(_table, c.toDbMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<int> deleteCase(int id) async {
    final db = await database;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countCases() async {
    final db = await database;
    return Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $_table')) ??
        0;
  }

  // ---------------------------------------------------------------------
  // Backup: entire DB -> in-memory .zip (one JSON per case + manifest).
  // Returns raw bytes; a platform-aware saver (backup_service.dart)
  // handles the actual download/share so this class stays pure Dart.
  // ---------------------------------------------------------------------

  Future<Uint8List> exportBackupZip() async {
    final cases = await getAllCases();
    final archive = Archive();
    const encoder = JsonEncoder.withIndent('  ');

    for (final c in cases) {
      final jsonStr = encoder.convert(c.toJson());
      final bytes = utf8.encode(jsonStr);
      // Safe, unique filename: case_<id>_<sanitized caseNo>.json
      final safeNo = c.caseNo.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final name = 'cases/case_${c.id}_$safeNo.json';
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    // Manifest for future restore/import validation.
    final manifest = encoder.convert({
      'app': 'HomeoMind',
      'schemaVersion': _dbVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'caseCount': cases.length,
    });
    final mBytes = utf8.encode(manifest);
    archive.addFile(ArchiveFile('manifest.json', mBytes.length, mBytes));

    final bytes = ZipEncoder().encode(archive);
    if (bytes == null) {
      throw StateError('Zip encoding returned null — nothing to export.');
    }
    return Uint8List.fromList(bytes);
  }

  /// Restore hook (Phase 2): reads case JSON files back from a backup zip.
  Future<int> importBackupZip(Uint8List zipBytes,
      {bool overwriteExisting = false}) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    var imported = 0;
    for (final file in archive.files) {
      if (!file.isFile || !file.name.startsWith('cases/')) continue;
      final map =
          jsonDecode(utf8.decode(file.content as List<int>)) as Map<String, dynamic>;
      final c = HomeoCase.fromJson(map)..id = null; // let DB assign new id
      try {
        await insertCase(c);
        imported++;
      } on DatabaseException {
        if (overwriteExisting) {
          final db = await database;
          await db.delete(_table, where: 'case_no = ?', whereArgs: [c.caseNo]);
          await insertCase(c);
          imported++;
        }
        // else: skip duplicate case_no silently
      }
    }
    return imported;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
