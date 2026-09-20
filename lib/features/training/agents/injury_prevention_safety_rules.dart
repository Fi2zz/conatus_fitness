import '../../../core/safety/safety_guard.dart';
import '../domain/injury_risk_report.dart';

/// 伤病史是否有效（"无"/空 视为无伤病）。
bool hasActiveInjuries(String injuries) {
  final trimmed = injuries.trim();
  return trimmed.isNotEmpty && trimmed != '无';
}

/// 伤病史非空但未识别任何风险部位 → 拦截（架构 14.3.1 精神：不得淡化风险）。
class MissingRiskAreaRule extends SafetyRule<InjuryRiskReport> {
  const MissingRiskAreaRule(this.injuries);

  final String injuries;

  @override
  String get name => 'missing_risk_area';

  @override
  SafetyVerdict check(InjuryRiskReport report) {
    if (!hasActiveInjuries(injuries) || report.riskAreas.isNotEmpty) {
      return const SafetyPassed();
    }
    return const SafetyBlocked('伤病史非空但报告未识别任何风险部位，请如实评估');
  }
}

/// 活跃伤病下风险等级不得为 low → 改写为 medium（保守优先）。
class ActiveInjuryLowRiskRule extends SafetyRule<InjuryRiskReport> {
  const ActiveInjuryLowRiskRule(this.injuries);

  final String injuries;

  @override
  String get name => 'active_injury_low_risk';

  @override
  SafetyVerdict check(InjuryRiskReport report) {
    if (!hasActiveInjuries(injuries) || report.riskLevel != 'low') {
      return const SafetyPassed();
    }
    return SafetyRewritten(
      InjuryRiskReport(
        riskAreas: report.riskAreas,
        riskLevel: 'medium',
        loadAnalysis: '${report.loadAnalysis}（安全改写：存在活跃伤病史，风险等级不应为 low）',
        preventiveActions: report.preventiveActions,
        conflictingExercises: report.conflictingExercises,
        safeAlternatives: report.safeAlternatives,
      ),
      '存在活跃伤病史，风险等级 low 已上调为 medium',
    );
  }
}

/// Injury Prevention 输出的硬规则组合。
List<SafetyRule<InjuryRiskReport>> injuryPreventionSafetyRules(
  String injuries,
) => [MissingRiskAreaRule(injuries), ActiveInjuryLowRiskRule(injuries)];
