import 'dart:convert';

import 'package:conatus/conatus.dart';

import '../../../core/safety/safety_guard.dart';
import '../domain/training_plan.dart';
import '../domain/training_plan_codec.dart';
import 'plan_output_schema.dart';
import 'plan_safety_rules.dart';

/// 计划提交校验工具：结构校验 + SafetyGuard 终审（架构 14.3.1）。
///
/// 校验失败返回结构化失败（触发 reflectAndRetry 反思重试）；
/// 通过时持有改写后/原样的 [TrainingPlan]，由 PlannerAgent 落库。
class ValidatePlanTool extends Tool {
  ValidatePlanTool(this.injuries);

  static const toolName = 'validate_plan';

  final String injuries;

  TrainingPlan? latestPlan;
  String status = '';

  @override
  String get name => toolName;

  @override
  String get description =>
      '提交训练计划做结构校验与安全终审（计划字段结构即本工具参数）。'
      '完成计划后必须调用；校验通过后，把返回的 JSON 原样作为最终回复输出，'
      '不要附加任何文字。';

  @override
  List<ParamSpec> get params => planOutputParams();

  @override
  Future<ToolResult> call(ToolContext context) async {
    final plan = TrainingPlanCodec.tryParseMap(context.arguments);
    if (plan == null) {
      const message =
          '计划未通过 JSON 结构校验：weeks/sessions/exercises '
          '结构不完整，或 sets/rest_seconds/target_rpe 数值越界';
      return ToolResult.failure(
        message,
        error: const ToolError('plan_invalid', message),
      );
    }
    final verdict = SafetyGuard<TrainingPlan>(
      rules: planSafetyRules(injuries),
    ).check(plan);
    switch (verdict) {
      case SafetyBlocked(:final reason):
        return ToolResult.failure(
          '安全校验拦截：$reason。请替换冲突动作后重新提交',
          error: ToolError('safety_blocked', reason),
        );
      case SafetyRewritten(:final rewritten, :final reason):
        latestPlan = rewritten;
        status = 'rewritten';
        return ToolResult.success(
          '校验通过（安全改写：$reason）。最终回复请原样输出：'
          '${jsonEncode(rewritten.toJson())}',
          value: rewritten,
        );
      case SafetyPassed():
        latestPlan = plan;
        status = 'passed';
        return ToolResult.success(
          '校验通过。最终回复请原样输出该 JSON，不要附加文字：'
          '${jsonEncode(plan.toJson())}',
          value: plan,
        );
    }
  }
}
