import 'dart:convert';

import 'injury_risk_report.dart';

/// 伤病风险报告 JSON codec：结构解析 + 枚举校验。
abstract final class InjuryRiskReportCodec {
  static InjuryRiskReport? tryParse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, Object?>) return null;
    return tryParseMap(decoded);
  }

  /// 解析已结构化的报告对象（function calling 的工具参数即此形态）。
  static InjuryRiskReport? tryParseMap(Map<String, Object?> decoded) {
    final level = decoded['risk_level'];
    final areas = _strings(decoded['risk_areas']);
    final actions = _strings(decoded['preventive_actions']);
    final analysis = decoded['load_analysis'];
    if (level is! String || !InjuryRiskReport.levels.contains(level)) {
      return null;
    }
    // risk_areas 允许为空数组（无伤病、无风险的合法结论）；
    // 「伤病史非空却报告无风险」的语义拦截交给 SafetyGuard 硬规则。
    if (areas == null) {
      return null;
    }
    if (actions == null || actions.isEmpty) return null;
    if (analysis is! String || analysis.isEmpty) return null;
    return InjuryRiskReport(
      riskAreas: areas,
      riskLevel: level,
      loadAnalysis: analysis,
      preventiveActions: actions,
      conflictingExercises:
          _strings(decoded['conflicting_exercises']) ?? const <String>[],
      safeAlternatives:
          _strings(decoded['safe_alternatives']) ?? const <String>[],
    );
  }

  static List<String>? _strings(Object? value) {
    if (value is! List) return null;
    return [
      for (final item in value)
        if (item != null) item.toString(),
    ];
  }

  static Map<String, Object?> toJson(InjuryRiskReport report) =>
      <String, Object?>{
        'risk_areas': report.riskAreas,
        'risk_level': report.riskLevel,
        'load_analysis': report.loadAnalysis,
        'preventive_actions': report.preventiveActions,
        'conflicting_exercises': report.conflictingExercises,
        'safe_alternatives': report.safeAlternatives,
      };
}
