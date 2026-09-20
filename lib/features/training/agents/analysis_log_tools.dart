import 'dart:convert';

import 'package:conatus/conatus.dart';

import '../data/workout_logs_dao.dart';

/// 日志查询工具（架构 5.2）：按动作/时间段查询训练记录。
class WorkoutLogQueryTool extends Tool {
  WorkoutLogQueryTool(this.dao);

  static const toolName = 'workout_log_query';

  final WorkoutLogsDao dao;

  @override
  String get name => toolName;

  @override
  String get description =>
      '按动作名称与时间窗口查询训练记录（每组一条）。'
      '引用任何训练数据前必须先调用本工具取数，禁止编造数值。';

  @override
  List<ParamSpec> get params => <ParamSpec>[
        ParamSpec.string('exercise', description: '动作名称，省略则查询全部动作'),
        ParamSpec.integer('days', description: '回看天数，默认 30'),
      ];

  @override
  Future<ToolResult> call(ToolContext context) async {
    final exercise = context.string('exercise');
    final days = context.integer('days') ?? 30;
    final since = DateTime.now().subtract(Duration(days: days));
    final logs = await dao.listSince(since, exercise: exercise);
    if (logs.isEmpty) {
      return ToolResult.success('查询窗口内无训练记录（动作=${exercise ?? '全部'}，回看 $days 天）');
    }
    final body = jsonEncode([for (final log in logs) _toJson(log)]);
    return ToolResult.success('共 ${logs.length} 条记录：$body');
  }

  Map<String, Object?> _toJson(WorkoutSetLog log) => <String, Object?>{
        'exercise': log.exercise,
        'set': log.setNumber,
        'weight': log.weight,
        'reps': log.reps,
        if (log.rpe != null) 'rpe': log.rpe,
        'date': log.performedAt.toIso8601String(),
      };
}
