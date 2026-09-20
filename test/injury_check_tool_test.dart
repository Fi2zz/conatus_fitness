import 'package:flutter_test/flutter_test.dart';

import 'package:conatus/conatus.dart' show ToolCall, ToolContext;
import 'package:conatus_fitness/features/training/agents/injury_check_tool.dart';

void main() {
  test('膝伤 + 深蹲 → 结构化失败', () async {
    final tool = InjuryCheckTool('膝盖旧伤');
    final result = await tool.call(ToolContext(ToolCall(
      name: InjuryCheckTool.toolName,
      arguments: {'exercise': '深蹲'},
    )));
    expect(result.isError, isTrue);
    expect(result.error?.code, 'injury_conflict');
    expect(result.content, contains('替换'));
  });

  test('膝伤 + 卧推 → 通过', () async {
    final tool = InjuryCheckTool('膝盖旧伤');
    final result = await tool.call(ToolContext(ToolCall(
      name: InjuryCheckTool.toolName,
      arguments: {'exercise': '卧推'},
    )));
    expect(result.isError, isFalse);
  });

  test('无伤病 → 任意动作通过', () async {
    final tool = InjuryCheckTool('无');
    final result = await tool.call(ToolContext(ToolCall(
      name: InjuryCheckTool.toolName,
      arguments: {'exercise': '深蹲'},
    )));
    expect(result.isError, isFalse);
  });
}
