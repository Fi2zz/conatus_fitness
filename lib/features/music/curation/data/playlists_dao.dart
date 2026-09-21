import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/schema.dart';
import '../../domain/music_playlist.dart';
import '../../domain/music_playlist_codec.dart';

/// playlists 表中的一条持久化歌单。
class StoredPlaylist {
  const StoredPlaylist({
    required this.id,
    required this.playlist,
    required this.createdAt,
  });

  final String id;
  final MusicPlaylist playlist;
  final DateTime createdAt;
}

/// playlists 表读写（架构 10.1）。SafetyGuard 终审结论走 event_log 追溯。
class PlaylistsDao {
  PlaylistsDao(this._db);

  final Database _db;

  Future<StoredPlaylist> save(MusicPlaylist playlist) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    await _db.insert(Tables.playlists, <String, Object?>{
      'id': id,
      'name': playlist.name,
      'payload': jsonEncode(playlist.toJson()),
      'created_at': now,
    });
    return StoredPlaylist(
      id: id,
      playlist: playlist,
      createdAt: DateTime.parse(now),
    );
  }

  Future<List<StoredPlaylist>> listLatest({int limit = 20}) async {
    final rows = await _db.query(
      Tables.playlists,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return [for (final row in rows) _fromRow(row)].nonNulls.toList();
  }

  Future<StoredPlaylist?> findById(String id) async {
    final rows = await _db.query(
      Tables.playlists,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  StoredPlaylist? _fromRow(Map<String, Object?> row) {
    final playlist = MusicPlaylistCodec.tryParse(
      row['payload']?.toString() ?? '',
    );
    if (playlist == null) return null;
    return StoredPlaylist(
      id: row['id'].toString(),
      playlist: playlist,
      createdAt: DateTime.parse(row['created_at'].toString()),
    );
  }
}
