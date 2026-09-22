import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:conatus/conatus.dart' show ToolCall, ToolContext, ToolResult;
import 'package:conatus_fitness/features/training/agents/validate_plan_tool.dart';

const validPlan = '''
{
  "weeks": [{"week_number": 1, "sessions": [{"day": "Monday", "focus": "下肢",
    "exercises": [{"name": "深蹲", "sets": 5, "reps": "5", "rest_seconds": 180,
    "target_rpe": 8, "safety_note": "膝伤保护：箱式深蹲"}]}]}],
  "safety_notes": ""
}
''';

Future<ToolResult> submit(ValidatePlanTool tool, String json) => tool.call(
  ToolContext(
    ToolCall(
      name: ValidatePlanTool.toolName,
      arguments: jsonDecode(json) as Map<String, Object?>,
    ),
  ),
);

void main() {
  test('合法计划 → 通过并持有 latestPlan', () async {
    final tool = ValidatePlanTool('无');
    await submit(tool, validPlan);
    expect(tool.latestPlan, isNotNull);
    expect(tool.status, 'passed');
    expect(
      tool.latestPlan!.weeks.first.sessions.first.exercises.first.name,
      '深蹲',
    );
  });

  test('结构非法 → plan_invalid 失败', () async {
    final tool = ValidatePlanTool('无');
    await submit(tool, '{"weeks": []}');
    expect(tool.latestPlan, isNull);
  });

  test('伤病冲突未加注 → 拦截', () async {
    final tool = ValidatePlanTool('膝盖旧伤');
    final broken = validPlan.replaceAll(
      '"safety_note": "膝伤保护：箱式深蹲"',
      '"safety_note": null',
    );
    final result = await submit(tool, broken);
    expect(result.isError, isTrue);
    expect(result.error?.code, 'safety_blocked');
  });

  test('RPE 超标 → 通过但被安全改写', () async {
    final tool = ValidatePlanTool('无');
    final over = validPlan.replaceAll('"target_rpe": 8', '"target_rpe": 9.5');
    final result = await submit(tool, over);
    expect(result.isError, isFalse);
    expect(tool.status, 'rewritten');
    expect(
      tool.latestPlan!.weeks.first.sessions.first.exercises.first.targetRpe,
      9,
    );
    expect(result.content, contains('安全改写'));
  });

  test('计划结构由工具参数下发（不再写进系统提示词）', () {
    final parameters = ValidatePlanTool('无').toSchema()['parameters'] as Map;
    final properties = parameters['properties'] as Map;
    expect(properties.keys, containsAll(<String>['weeks', 'safety_notes']));
    expect(parameters['required'], contains('weeks'));
    final week = (properties['weeks'] as Map)['items'] as Map;
    final session = ((week['properties'] as Map)['sessions'] as Map)['items'];
    final exercise =
        ((session['properties'] as Map)['exercises'] as Map)['items'];
    expect(
      (exercise['properties'] as Map).keys,
      containsAll(<String>[
        'name',
        'sets',
        'reps',
        'rest_seconds',
        'target_rpe',
        'safety_note',
      ]),
    );
  });
}
