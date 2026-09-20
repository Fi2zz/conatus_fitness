import 'package:sqflite/sqflite.dart';

import '../../../data/schema.dart';

/// agent_memory 表读写（架构 10.2：Summary Memory 落点）。
class AgentMemoryDao {
  AgentMemoryDao(this._db);

  final Database _db;

  Future<void> save({
    required String domain,
    required String kind,
    required String content,
  }) async {
    await _db.insert(Tables.agentMemory, <String, Object?>{
      'domain': domain,
      'kind': kind,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// 某域最近的分析/建议结论（记忆复用：保持结论一致性，架构 5.2）。
  Future<List<String>> listLatest({
    required String domain,
    String? kind,
    int limit = 20,
  }) async {
    final rows = await _db.query(
      Tables.agentMemory,
      where: ['domain = ?', if (kind != null) 'kind = ?'].join(' AND '),
      whereArgs: [domain, ?kind],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return [for (final row in rows) row['content'].toString()];
  }
}
