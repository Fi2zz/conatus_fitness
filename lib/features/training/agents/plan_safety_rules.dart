import '../../../core/safety/safety_guard.dart';
import '../domain/training_plan.dart';
import 'rpe_cap_rule.dart';

/// 伤病关键词 → 冲突动作关键词。MVP 硬编码表，后续可迁移配置。
const injuryConflicts = <String, List<String>>{
  '膝': ['深蹲', '弓步', '跳跃', '腿举'],
  '腰': ['硬拉', '早安式', '山羊挺身'],
  '肩': ['卧推', '推举', '双杠'],
  '腕': ['卧推', '俯卧撑'],
  '踝': ['跳绳', '跳跃', '跑步'],
};

/// 单个动作与伤病史的冲突判定；[note] 非空视为已处理。
bool exerciseConflictsWith(String exercise, String injuries, String? note) {
  for (final entry in injuryConflicts.entries) {
    final injured = injuries.contains(entry.key);
    final involved = entry.value.any(exercise.contains);
    if (injured && involved && (note == null || note.isEmpty)) return true;
  }
  return false;
}

/// 伤病史相关动作出现且未替换 → 拦截（架构 14.3.1）。
class InjuryMovementRule extends SafetyRule<TrainingPlan> {
  InjuryMovementRule(this.injuries);

  final String injuries;

  @override
  String get name => 'injury_movement_blocked';

  @override
  SafetyVerdict check(TrainingPlan plan) {
    for (final week in plan.weeks) {
      for (final session in week.sessions) {
        for (final exercise in session.exercises) {
          if (exerciseConflictsWith(
            exercise.name,
            injuries,
            exercise.safetyNote,
          )) {
            return SafetyBlocked('动作「${exercise.name}」与伤病史冲突且未加注');
          }
        }
      }
    }
    return const SafetyPassed();
  }
}

/// Planner 输出的硬规则组合（架构 14.3.1）。
List<SafetyRule<TrainingPlan>> planSafetyRules(String injuries) => [
  InjuryMovementRule(injuries),
  const RpeCapRule(),
];
