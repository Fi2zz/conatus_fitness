import 'dart:convert';

import 'package:conatus/conatus.dart';

import '../../../core/safety/safety_guard.dart';
import '../domain/training_suggestion.dart';
import '../domain/training_suggestion_codec.dart';
import 'suggestion_safety_rules.dart';

/// 建议提交校验工具：结构校验 + SafetyGuard 终审（架构 14.3.1）。
///
/// 校验失败返回结构化失败（触发 reflectAndRetry 反思重试）；
/// 通过/改写后持有 [TrainingSuggestion]，由 SuggestionAgent 落库。
class ValidateSuggestionTool extends Tool {
  ValidateSuggestionTool({required this.recoveryScore, required this.painReported});

  static const toolName = 'validate_suggestion';

  final int recoveryScore;
  final bool painReported;

  TrainingSuggestion? latestSuggestion;
  String status = '';

  @override
  String get name => toolName;

  @override
  String get description =>
      '提交训练建议 JSON 做结构校验与安全终审。完成建议后必须调用；'
      '校验通过后，把返回的 JSON 原样作为最终回复输出，不要附加任何文字。';

  @override
  List<ParamSpec> get params => <ParamSpec>[
        ParamSpec.string('suggestion_json', description: '完整的训练建议 JSON', required: true),
      ];

  @override
  Future<ToolResult> call(ToolContext context) async {
    final suggestion = TrainingSuggestionCodec.tryParse(context.str('suggestion_json'));
    if (suggestion == null) {
      const message = '建议未通过 JSON 结构校验：suggestion_type 必须是 '
          'increase_load/maintain/deload/rest 之一，reasoning 不能为空';
      return ToolResult.failure(
        message,
        error: const ToolError('suggestion_invalid', message),
      );
    }
    final verdict = SafetyGuard<TrainingSuggestion>(
      rules: suggestionSafetyRules(
        recoveryScore: recoveryScore,
        painReported: painReported,
      ),
    ).check(suggestion);
    switch (verdict) {
      case SafetyBlocked(:final reason):
        return ToolResult.failure(
          '安全校验拦截：$reason',
          error: ToolError('safety_blocked', reason),
        );
      case SafetyRewritten(:final rewritten, :final reason):
        latestSuggestion = rewritten;
        status = 'rewritten';
        return ToolResult.success(
          '校验通过（安全改写：$reason）。最终回复请原样输出：'
          '${jsonEncode(TrainingSuggestionCodec.toJson(rewritten))}',
          value: rewritten,
        );
      case SafetyPassed():
        latestSuggestion = suggestion;
        status = 'passed';
        return ToolResult.success(
          '校验通过。最终回复请原样输出该建议 JSON，不要附加文字',
          value: suggestion,
        );
    }
  }
}
