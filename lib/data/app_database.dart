import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

/// 本地优先 SQLite 入口（架构 10.1）：App 与 Agent 共享同一数据库。
class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  Database get db => _db;

  static Future<AppDatabase> open({String? path}) async {
    final dbPath = path ?? p.join(await getDatabasesPath(), 'conatus_fitness.db');
    final database = await openDatabase(
      dbPath,
      version: SchemaV1.version,
      onCreate: (db, version) async {
        for (final statement in SchemaV1.statements) {
          await db.execute(statement);
        }
      },
    );
    return AppDatabase._(database);
  }

  Future<void> close() => _db.close();
}
