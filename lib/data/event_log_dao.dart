import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'schema.dart';

/// event_log 表写入（架构 14.3.1：SafetyGuard 改写/拦截需可追溯）。
class EventLogDao {
  EventLogDao(this._db);

  final Database _db;

  Future<void> record(
    String eventId,
    String sourceAgent,
    Map<String, Object?> payload,
  ) async {
    await _db.insert(Tables.eventLog, <String, Object?>{
      'event_id': eventId,
      'trace_id': eventId,
      'source_agent': sourceAgent,
      'payload': jsonEncode(payload),
      'occurred_at': DateTime.now().toIso8601String(),
    });
  }
}
