import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:conatus/conatus.dart' show ToolCall, ToolContext, ToolResult;
import 'package:conatus_fitness/features/training/agents/validate_suggestion_tool.dart';

const validSuggestion =
    '{"suggestion_type":"increase_load","reasoning":"容量连续两周上升",'
    '"next_session_focus":"下肢力量","recommended_music_mood":"high_energy",'
    '"safety_flag":false}';

Future<ToolResult> submit(ValidateSuggestionTool tool, String json) =>
    tool.call(
      ToolContext(
        ToolCall(
          name: ValidateSuggestionTool.toolName,
          arguments: jsonDecode(json) as Map<String, Object?>,
        ),
      ),
    );

void main() {
  test('合法建议 → 通过并持有 latestSuggestion', () async {
    final tool = ValidateSuggestionTool(recoveryScore: 8, painReported: false);
    await submit(tool, validSuggestion);
    expect(tool.latestSuggestion, isNotNull);
    expect(tool.status, 'passed');
    expect(tool.latestSuggestion!.suggestionType, 'increase_load');
  });

  test('结构非法 → suggestion_invalid 失败', () async {
    final tool = ValidateSuggestionTool(recoveryScore: 8, painReported: false);
    final result = await submit(tool, '{"suggestion_type":"whatever"}');
    expect(result.isError, isTrue);
    expect(result.error?.code, 'suggestion_invalid');
    expect(tool.latestSuggestion, isNull);
  });

  test('恢复评分 1 → 通过但被安全改写为 rest', () async {
    final tool = ValidateSuggestionTool(recoveryScore: 1, painReported: false);
    final result = await submit(tool, validSuggestion);
    expect(result.isError, isFalse);
    expect(tool.status, 'rewritten');
    expect(tool.latestSuggestion!.suggestionType, 'rest');
    expect(result.content, contains('安全改写'));
  });

  test('报告疼痛 → 通过但被安全改写为 rest', () async {
    final tool = ValidateSuggestionTool(recoveryScore: 9, painReported: true);
    await submit(tool, validSuggestion);
    expect(tool.status, 'rewritten');
    expect(tool.latestSuggestion!.suggestionType, 'rest');
  });

  test('建议结构由工具参数下发（不再写进系统提示词）', () {
    final tool = ValidateSuggestionTool(recoveryScore: 8, painReported: false);
    final parameters = tool.toSchema()['parameters'] as Map;
    final properties = parameters['properties'] as Map;
    expect((properties['suggestion_type'] as Map)['enum'], [
      'increase_load',
      'maintain',
      'deload',
      'rest',
    ]);
    expect(
      parameters['required'],
      containsAll(<String>['suggestion_type', 'reasoning']),
    );
  });
}
