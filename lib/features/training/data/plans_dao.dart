import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../data/schema.dart';
import '../domain/training_plan.dart';
import '../domain/training_plan_codec.dart';

/// training_plans 表中的一条持久化计划。
class StoredPlan {
  const StoredPlan({
    required this.id,
    required this.plan,
    required this.safetyStatus,
    required this.createdAt,
  });

  final String id;
  final TrainingPlan plan;
  final String safetyStatus;
  final DateTime createdAt;
}

/// training_plans 表读写（架构 10.1）。
class PlansDao {
  PlansDao(this._db);

  final Database _db;

  Future<StoredPlan> save(
    TrainingPlan plan, {
    required String source,
    required String safetyStatus,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    await _db.insert(Tables.trainingPlans, <String, Object?>{
      'id': id,
      'payload': jsonEncode(plan.toJson()),
      'source': source,
      'safety_status': safetyStatus,
      'created_at': now,
    });
    return StoredPlan(
      id: id,
      plan: plan,
      safetyStatus: safetyStatus,
      createdAt: DateTime.parse(now),
    );
  }

  Future<List<StoredPlan>> listLatest({int limit = 20}) async {
    final rows = await _db.query(
      Tables.trainingPlans,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return [for (final row in rows) _fromRow(row)].nonNulls.toList();
  }

  Future<StoredPlan?> findById(String id) async {
    final rows = await _db.query(
      Tables.trainingPlans,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  StoredPlan? _fromRow(Map<String, Object?> row) {
    final plan = TrainingPlanCodec.tryParse(row['payload']?.toString() ?? '');
    if (plan == null) return null;
    return StoredPlan(
      id: row['id'].toString(),
      plan: plan,
      safetyStatus: row['safety_status'].toString(),
      createdAt: DateTime.parse(row['created_at'].toString()),
    );
  }
}
