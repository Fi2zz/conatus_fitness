import 'dart:convert';

import 'training_plan.dart';

/// LLM 输出 → [TrainingPlan] 的解析与结构校验（架构 5.1）。
///
/// 校验失败返回 null，由 Planner Agent 触发重新生成（≤ 2 次重试）。
abstract final class TrainingPlanCodec {
  static TrainingPlan? tryParse(String raw) {
    final root = _decode(raw);
    if (root == null) return null;
    return tryParseMap(root);
  }

  /// 解析已结构化的计划对象（function calling 的工具参数即此形态）。
  static TrainingPlan? tryParseMap(Map<String, Object?> root) {
    final weeks = _parseWeeks(root['weeks']);
    if (weeks == null) return null;
    return TrainingPlan(
      weeks: weeks,
      safetyNotes: root['safety_notes']?.toString() ?? '',
    );
  }

  static Map<String, dynamic>? _decode(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text
          .replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '')
          .replaceAll('```', '')
          .trim();
    }
    try {
      final value = jsonDecode(text);
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }

  static List<PlanWeek>? _parseWeeks(Object? node) {
    if (node is! List || node.isEmpty) return null;
    final weeks = <PlanWeek>[];
    for (final weekNode in node) {
      if (weekNode is! Map<String, dynamic>) return null;
      final number = weekNode['week_number'];
      final sessions = _parseSessions(weekNode['sessions']);
      if (number is! int || sessions == null || sessions.isEmpty) return null;
      weeks.add(PlanWeek(weekNumber: number, sessions: sessions));
    }
    return weeks;
  }

  static List<PlanSession>? _parseSessions(Object? node) {
    if (node is! List || node.isEmpty) return null;
    final sessions = <PlanSession>[];
    for (final sessionNode in node) {
      if (sessionNode is! Map<String, dynamic>) return null;
      final exercises = _parseExercises(sessionNode['exercises']);
      final day = sessionNode['day']?.toString() ?? '';
      final focus = sessionNode['focus']?.toString() ?? '';
      if (exercises == null || exercises.isEmpty || day.isEmpty) return null;
      sessions.add(PlanSession(day: day, focus: focus, exercises: exercises));
    }
    return sessions;
  }

  static List<PlanExercise>? _parseExercises(Object? node) {
    if (node is! List || node.isEmpty) return null;
    final exercises = <PlanExercise>[];
    for (final exerciseNode in node) {
      if (exerciseNode is! Map<String, dynamic>) return null;
      final exercise = _parseExercise(exerciseNode);
      if (exercise == null) return null;
      exercises.add(exercise);
    }
    return exercises;
  }

  static PlanExercise? _parseExercise(Map<String, dynamic> node) {
    final name = node['name']?.toString() ?? '';
    final sets = node['sets'];
    final reps = node['reps']?.toString() ?? '';
    final rest = node['rest_seconds'];
    final rpe = node['target_rpe'];
    if (name.isEmpty || reps.isEmpty || sets is! int || sets <= 0) return null;
    if (rest is! int || rest <= 0 || rpe is! num) return null;
    final targetRpe = rpe.toDouble();
    if (targetRpe < 1 || targetRpe > 10) return null;
    return PlanExercise(
      name: name,
      sets: sets,
      reps: reps,
      restSeconds: rest,
      targetRpe: targetRpe,
      safetyNote: node['safety_note']?.toString(),
    );
  }
}
