import 'package:sqflite/sqflite.dart';

import '../../../data/schema.dart';

/// music_preferences 表中的一条偏好反馈（架构 10.1）。
class MusicSignal {
  const MusicSignal({
    required this.signal,
    required this.trackId,
    required this.context,
    required this.recordedAt,
  });

  final String signal;
  final String? trackId;
  final String? context;
  final DateTime recordedAt;
}

/// music_preferences 表读取（架构 10.4：隐式与显式反馈）。
class MusicPrefsDao {
  MusicPrefsDao(this._db);

  final Database _db;

  Future<List<MusicSignal>> listSignals({int limit = 50}) async {
    final rows = await _db.query(
      Tables.musicPreferences,
      orderBy: 'recorded_at DESC',
      limit: limit,
    );
    return [
      for (final row in rows)
        MusicSignal(
          signal: row['signal'].toString(),
          trackId: row['track_id']?.toString(),
          context: row['context']?.toString(),
          recordedAt: DateTime.parse(row['recorded_at'].toString()),
        ),
    ];
  }
}
