import 'package:sqflite/sqflite.dart';

import '../../../data/schema.dart';

/// workout_logs 表中的一条组记录。
class WorkoutSetLog {
  const WorkoutSetLog({
    required this.exercise,
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.sessionId,
    required this.performedAt,
    this.rpe,
  });

  final String exercise;
  final int setNumber;
  final double weight;
  final int reps;
  final double? rpe;
  final String sessionId;
  final DateTime performedAt;

  double get volume => weight * reps;
}

/// workout_logs 表读取（架构 10.1）。
class WorkoutLogsDao {
  WorkoutLogsDao(this._db);

  final Database _db;

  /// 写入一条组记录。
  Future<void> save(WorkoutSetLog log) =>
      _db.insert(Tables.workoutLogs, <String, Object?>{
        'exercise': log.exercise,
        'set_number': log.setNumber,
        'weight': log.weight,
        'reps': log.reps,
        'rpe': log.rpe,
        'session_id': log.sessionId,
        'performed_at': log.performedAt.toIso8601String(),
      });

  /// 同一次训练课内某动作的下一个组号（从 1 开始）。
  Future<int> nextSetNumber(String sessionId, String exercise) async {
    final rows = await _db.rawQuery(
      'SELECT MAX(set_number) AS max_set FROM ${Tables.workoutLogs} '
      'WHERE session_id = ? AND exercise = ?',
      [sessionId, exercise],
    );
    final value = rows.first['max_set'];
    return value == null ? 1 : (value as num).toInt() + 1;
  }

  /// [since] 起的记录，时间升序（便于趋势计算）；可按动作过滤。
  Future<List<WorkoutSetLog>> listSince(
    DateTime since, {
    String? exercise,
  }) async {
    final rows = await _db.query(
      Tables.workoutLogs,
      where: [
        'performed_at >= ?',
        if (exercise != null) 'exercise = ?',
      ].join(' AND '),
      whereArgs: [since.toIso8601String(), ?exercise],
      orderBy: 'performed_at ASC',
    );
    return [for (final row in rows) _fromRow(row)];
  }

  WorkoutSetLog _fromRow(Map<String, Object?> row) => WorkoutSetLog(
    exercise: row['exercise'].toString(),
    setNumber: (row['set_number'] as num).toInt(),
    weight: (row['weight'] as num).toDouble(),
    reps: (row['reps'] as num).toInt(),
    rpe: row['rpe'] == null ? null : (row['rpe'] as num).toDouble(),
    sessionId: row['session_id'].toString(),
    performedAt: DateTime.parse(row['performed_at'].toString()),
  );
}
