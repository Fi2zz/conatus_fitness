import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:conatus_fitness/core/safety/safety_guard.dart';
import 'package:conatus_fitness/features/training/agents/injury_prevention_safety_rules.dart';
import 'package:conatus_fitness/features/training/domain/injury_risk_report.dart';
import 'package:conatus_fitness/features/training/domain/injury_risk_report_codec.dart';

InjuryRiskReport report({
  List<String> areas = const ['膝'],
  String level = 'medium',
}) => InjuryRiskReport(
  riskAreas: areas,
  riskLevel: level,
  loadAnalysis: '深蹲近期容量上升 20%，RPE 8.5',
  preventiveActions: ['替换箱式深蹲', '降低负荷 10%'],
  conflictingExercises: const ['深蹲'],
  safeAlternatives: const ['箱式深蹲'],
);

void main() {
  group('伤病防护硬规则', () {
    test('伤病史非空且风险 low → 改写为 medium', () {
      final verdict = ActiveInjuryLowRiskRule(
        '膝盖旧伤',
      ).check(report(level: 'low'));
      expect(verdict, isA<SafetyRewritten<InjuryRiskReport>>());
      final rewritten =
          (verdict as SafetyRewritten<InjuryRiskReport>).rewritten;
      expect(rewritten.riskLevel, 'medium');
      expect(rewritten.loadAnalysis, contains('安全改写'));
    });

    test('无伤病时 low 放行', () {
      expect(
        ActiveInjuryLowRiskRule('无').check(report(level: 'low')),
        isA<SafetyPassed>(),
      );
    });

    test('伤病史非空但风险部位为空 → 拦截', () {
      final verdict = MissingRiskAreaRule('膝盖旧伤').check(report(areas: []));
      expect(verdict, isA<SafetyBlocked>());
    });

    test('组合规则经 SafetyGuard 生效', () {
      final verdict = SafetyGuard<InjuryRiskReport>(
        rules: injuryPreventionSafetyRules('膝盖旧伤'),
      ).check(report(level: 'low'));
      expect(verdict, isA<SafetyRewritten<InjuryRiskReport>>());
    });
  });

  group('InjuryRiskReportCodec', () {
    test('合法 JSON → 解析成功', () {
      final parsed = InjuryRiskReportCodec.tryParse(
        '{"risk_areas":["膝"],"risk_level":"high","load_analysis":"刺激频繁",'
        '"preventive_actions":["减量"],"conflicting_exercises":["深蹲"],'
        '"safe_alternatives":["箱式深蹲"]}',
      );
      expect(parsed, isNotNull);
      expect(parsed!.riskLevel, 'high');
      expect(parsed.riskAreas, ['膝']);
    });

    test('非法枚举 / 缺失必填字段 / 坏 JSON → null', () {
      // risk_areas 缺失 → 结构非法（空数组合法，语义拦截归 SafetyGuard）
      expect(
        InjuryRiskReportCodec.tryParse(
          '{"risk_level":"low",'
          '"load_analysis":"x","preventive_actions":["a"]}',
        ),
        isNull,
      );
      expect(
        InjuryRiskReportCodec.tryParse(
          '{"risk_areas":["膝"],"risk_level":"none",'
          '"load_analysis":"x","preventive_actions":["a"]}',
        ),
        isNull,
      );
      expect(InjuryRiskReportCodec.tryParse('broken'), isNull);
    });

    test('toJson 往返一致', () {
      final original = report();
      final parsed = InjuryRiskReportCodec.tryParse(
        jsonEncode(InjuryRiskReportCodec.toJson(original)),
      );
      expect(parsed, isNotNull);
      expect(parsed!.riskLevel, 'medium');
      expect(parsed.riskAreas, original.riskAreas);
      expect(parsed.preventiveActions, original.preventiveActions);
    });
  });
}
