import 'dart:convert';

import 'package:conatus/conatus.dart';

import '../../../core/safety/safety_guard.dart';
import '../domain/injury_risk_report.dart';
import '../domain/injury_risk_report_codec.dart';
import 'injury_prevention_safety_rules.dart';
import 'risk_report_output_schema.dart';

/// 风险报告提交校验工具：结构校验 + SafetyGuard 终审。
class ValidateRiskReportTool extends Tool {
  ValidateRiskReportTool(this.injuries);

  static const toolName = 'validate_risk_report';

  final String injuries;

  InjuryRiskReport? latestReport;
  String status = '';

  @override
  String get name => toolName;

  @override
  String get description =>
      '提交伤病风险报告做结构校验与安全终审（报告字段结构即本工具参数）。'
      '完成评估后必须调用；校验通过后，把返回的 JSON 原样作为最终回复输出，'
      '不要附加任何文字。';

  @override
  List<ParamSpec> get params => riskReportOutputParams();

  @override
  Future<ToolResult> call(ToolContext context) async {
    final report = InjuryRiskReportCodec.tryParseMap(context.arguments);
    if (report == null) {
      const message =
          '报告未通过 JSON 结构校验：risk_level 必须是 low/medium/high，'
          'risk_areas 与 preventive_actions 不能为空，load_analysis 不能为空';
      return ToolResult.failure(
        message,
        error: const ToolError('report_invalid', message),
      );
    }
    final verdict = SafetyGuard<InjuryRiskReport>(
      rules: injuryPreventionSafetyRules(injuries),
    ).check(report);
    switch (verdict) {
      case SafetyBlocked(:final reason):
        return ToolResult.failure(
          '安全校验拦截：$reason',
          error: ToolError('safety_blocked', reason),
        );
      case SafetyRewritten(:final rewritten, :final reason):
        latestReport = rewritten;
        status = 'rewritten';
        return ToolResult.success(
          '校验通过（安全改写：$reason）。最终回复请原样输出：'
          '${jsonEncode(InjuryRiskReportCodec.toJson(rewritten))}',
          value: rewritten,
        );
      case SafetyPassed():
        latestReport = report;
        status = 'passed';
        return ToolResult.success(
          '校验通过。最终回复请原样输出该 JSON，不要附加文字：'
          '${jsonEncode(InjuryRiskReportCodec.toJson(report))}',
          value: report,
        );
    }
  }
}
