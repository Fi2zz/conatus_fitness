import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:conatus/conatus.dart' show ToolCall, ToolContext, ToolResult;
import 'package:conatus_fitness/features/training/agents/validate_risk_report_tool.dart';

const validReport =
    '{"risk_areas":["膝"],"risk_level":"medium","load_analysis":"深蹲容量上升",'
    '"preventive_actions":["减量10%"],"conflicting_exercises":["深蹲"],'
    '"safe_alternatives":["箱式深蹲"]}';

Future<ToolResult> submit(ValidateRiskReportTool tool, String json) =>
    tool.call(
      ToolContext(
        ToolCall(
          name: ValidateRiskReportTool.toolName,
          arguments: jsonDecode(json) as Map<String, Object?>,
        ),
      ),
    );

void main() {
  test('合法报告 → 通过并持有 latestReport', () async {
    final tool = ValidateRiskReportTool('膝盖旧伤');
    await submit(tool, validReport);
    expect(tool.latestReport, isNotNull);
    expect(tool.status, 'passed');
    expect(tool.latestReport!.riskAreas, ['膝']);
  });

  test('结构非法 → report_invalid 失败', () async {
    final tool = ValidateRiskReportTool('无');
    final result = await submit(tool, '{"risk_level":"huge"}');
    expect(result.isError, isTrue);
    expect(result.error?.code, 'report_invalid');
    expect(tool.latestReport, isNull);
  });

  test('活跃伤病 + low → 通过但被安全改写', () async {
    final tool = ValidateRiskReportTool('膝盖旧伤');
    final low = validReport.replaceAll(
      '"risk_level":"medium"',
      '"risk_level":"low"',
    );
    final result = await submit(tool, low);
    expect(result.isError, isFalse);
    expect(tool.status, 'rewritten');
    expect(tool.latestReport!.riskLevel, 'medium');
    expect(result.content, contains('安全改写'));
  });

  test('伤病史非空但未识别风险部位 → 拦截', () async {
    final tool = ValidateRiskReportTool('膝盖旧伤');
    final empty = validReport.replaceAll(
      '"risk_areas":["膝"]',
      '"risk_areas":[]',
    );
    final result = await submit(tool, empty);
    expect(result.isError, isTrue);
    expect(result.error?.code, 'safety_blocked');
  });

  test('报告结构由工具参数下发（不再写进系统提示词）', () {
    final parameters =
        ValidateRiskReportTool('无').toSchema()['parameters'] as Map;
    final properties = parameters['properties'] as Map;
    expect(
      properties.keys,
      containsAll(<String>[
        'risk_areas',
        'risk_level',
        'load_analysis',
        'preventive_actions',
        'conflicting_exercises',
        'safe_alternatives',
      ]),
    );
    expect((properties['risk_level'] as Map)['enum'], [
      'low',
      'medium',
      'high',
    ]);
  });
}
