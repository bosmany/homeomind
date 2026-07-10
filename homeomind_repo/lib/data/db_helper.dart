// db_helper.dart
// HomeoMind — storage on sembast (pure Dart, IndexedDB on web).
// No web workers, no WASM, no setup step. Cases + appointments.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

import '../models/case_model.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'homeomind.db';
  final _cases = intMapStoreFactory.store('cases');
  final _appts = intMapStoreFactory.store('appointments');

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final factory = kIsWeb ? databaseFactoryWeb : databaseFactoryIo;
    final db = await factory.openDatabase(_dbName);
    await _seedIfEmpty(db);
    return db;
  }

  Future<void> _seedIfEmpty(Database db) async {
    final count = await _cases.count(db);
    if (count > 0) return;
    final now = DateTime.now().toIso8601String();
    final demos = <Map<String, dynamic>>[
      {
        'caseNo': 'UB-101',
        'date': '2026-06-12',
        'patient': {'name': 'Ramesh Kulkarni', 'age': 46, 'sex': 'M', 'occupation': 'Accountant'},
        'chiefComplaint': {
          'complaint': 'Migraine, right-sided, throbbing',
          'location': 'Right temple to eye',
          'modalities': '< sun exposure, noise; > pressure, dark room',
          'duration': '8 years',
        },
        'prescription': {'remedy': 'Belladonna', 'potency': '200C', 'dose': 'Single dose, SL BD x 7d'},
        'followUps': <Map<String, dynamic>>[],
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'caseNo': 'UB-102',
        'date': '2026-06-25',
        'patient': {'name': 'Sadia Parveen', 'age': 33, 'sex': 'F', 'occupation': 'Teacher'},
        'chiefComplaint': {
          'complaint': 'Anxiety with palpitations, anticipatory worry',
          'modalities': '< before events, crowds; > company, reassurance',
          'duration': '2 years',
        },
        'prescription': {'remedy': 'Argentum Nitricum', 'potency': '30C', 'dose': 'BD x 15d'},
        'followUps': <Map<String, dynamic>>[],
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'caseNo': 'UB-103',
        'date': '2026-07-02',
        'patient': {'name': 'Arjun Mehta', 'age': 12, 'sex': 'M', 'occupation': 'Student'},
        'chiefComplaint': {
          'complaint': 'Recurrent tonsillitis, right side first',
          'modalities': '< cold drinks, weather change; > warm drinks',
          'duration': 'Since age 8',
        },
        'prescription': {'remedy': 'Lycopodium', 'potency': '30C', 'dose': 'OD x 10d'},
        'followUps': <Map<String, dynamic>>[],
        'createdAt': now,
        'updatedAt': now,
      },
    ];
    for (final d in demos) {
      final key = await _cases.add(db, d);
      await _cases.record(key).update(db, {'id': key});
    }
  }

  // ---------------- CASES ----------------

  Future<int> insertCase(HomeoCase c) async {
    final db = await database;
    c.updatedAt = DateTime.now().toIso8601String();
    if (c.createdAt.isEmpty) c.createdAt = c.updatedAt;
    final key = await _cases.add(db, c.toJson());
    c.id = key;
    await _cases.record(key).update(db, {'id': key});
    return key;
  }

  Future<HomeoCase?> getCase(int id) async {
    final db = await database;
    final rec = await _cases.record(id).get(db);
    if (rec == null) return null;
    try {
      return HomeoCase.fromJson(Map<String, dynamic>.from(rec));
    } catch (_) {
      return null;
    }
  }

  Future<List<HomeoCase>> getAllCases({String? search}) async {
    final db = await database;
    final records = await _cases.find(
      db,
      finder: Finder(sortOrders: [SortOrder('date', false)]),
    );
    final list = <HomeoCase>[];
    for (final r in records) {
      try {
        list.add(HomeoCase.fromJson(Map<String, dynamic>.from(r.value)));
      } catch (_) {}
    }
    if (search == null || search.trim().isEmpty) return list;
    final q = search.trim().toLowerCase();
    return list
        .where((c) =>
            c.patient.name.toLowerCase().contains(q) ||
            c.caseNo.toLowerCase().contains(q))
        .toList();
  }

  Future<int> updateCase(HomeoCase c) async {
    final db = await database;
    if (c.id == null) return 0;
    c.updatedAt = DateTime.now().toIso8601String();
    await _cases.record(c.id!).put(db, c.toJson());
    return 1;
  }

  Future<int> deleteCase(int id) async {
    final db = await database;
    await _cases.record(id).delete(db);
    return 1;
  }

  Future<int> countCases() async {
    final db = await database;
    return _cases.count(db);
  }

  Future<bool> caseNoExists(String caseNo) async {
    final db = await database;
    final rec = await _cases.findFirst(db,
        finder: Finder(filter: Filter.equals('caseNo', caseNo.trim())));
    return rec != null;
  }

  // ---------------- APPOINTMENTS ----------------

  Future<int> insertAppointment(Map<String, dynamic> a) async {
    final db = await database;
    a['createdAt'] = DateTime.now().toIso8601String();
    a['status'] = a['status'] ?? 'new';
    final key = await _appts.add(db, a);
    await _appts.record(key).update(db, {'id': key});
    return key;
  }

  Future<List<Map<String, dynamic>>> getAppointments() async {
    final db = await database;
    final records = await _appts.find(
      db,
      finder: Finder(sortOrders: [SortOrder('createdAt', false)]),
    );
    return records.map((r) => Map<String, dynamic>.from(r.value)).toList();
  }

  Future<void> setAppointmentStatus(int id, String status) async {
    final db = await database;
    await _appts.record(id).update(db, {'status': status});
  }

  Future<void> deleteAppointment(int id) async {
    final db = await database;
    await _appts.record(id).delete(db);
  }

  // ---------------- BACKUP ----------------

  Future<Uint8List> exportBackupZip() async {
    final cases = await getAllCases();
    final appts = await getAppointments();
    final archive = Archive();

    for (final c in cases) {
      final name = 'case_${c.caseNo.isEmpty ? c.id : c.caseNo}.json';
      final bytes =
          utf8.encode(const JsonEncoder.withIndent('  ').convert(c.toJson()));
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }
    final apptBytes =
        utf8.encode(const JsonEncoder.withIndent('  ').convert(appts));
    archive
        .addFile(ArchiveFile('appointments.json', apptBytes.length, apptBytes));

    final manifest = utf8.encode(jsonEncode({
      'app': 'HomeoMind',
      'exportedAt': DateTime.now().toIso8601String(),
      'caseCount': cases.length,
      'appointmentCount': appts.length,
    }));
    archive.addFile(ArchiveFile('manifest.json', manifest.length, manifest));

    final bytes = ZipEncoder().encode(archive);
    if (bytes == null) {
      throw StateError('Zip encoding returned null — nothing to export.');
    }
    return Uint8List.fromList(bytes);
  }
}
