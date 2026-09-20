/// Injury Prevention Agent 输出：伤病风险报告。
class InjuryRiskReport {
  const InjuryRiskReport({
    required this.riskAreas,
    required this.riskLevel,
    required this.loadAnalysis,
    required this.preventiveActions,
    required this.conflictingExercises,
    required this.safeAlternatives,
  });

  static const levels = <String>['low', 'medium', 'high'];

  final List<String> riskAreas;
  final String riskLevel;
  final String loadAnalysis;
  final List<String> preventiveActions;
  final List<String> conflictingExercises;
  final List<String> safeAlternatives;
}
