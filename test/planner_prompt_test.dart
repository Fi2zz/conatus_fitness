import 'package:flutter_test/flutter_test.dart';

import 'package:conatus_fitness/features/training/agents/planner_input.dart';
import 'package:conatus_fitness/features/training/agents/planner_prompt.dart';

void main() {
  test('system prompt 含约束与工具说明，不再含输出 Schema', () {
    final prompt = PlannerPrompt.system();
    expect(prompt, contains('伤病史相关动作必须替换或加注 safety_note'));
    expect(prompt, contains('injury_check'));
    expect(prompt, contains('validate_plan'));
    expect(prompt, isNot(contains('week_number')));
    expect(prompt, isNot(contains('target_rpe')));
  });

  test('userBrief 渲染全部画像字段', () {
    final prompt = PlannerPrompt.userBrief(
      const PlannerInput(
        goal: '增肌',
        fitnessLevel: '中级',
        daysPerWeek: 4,
        equipment: '健身房',
        injuries: '膝盖旧伤',
        weeks: 2,
      ),
    );
    expect(prompt, contains('目标：增肌'));
    expect(prompt, contains('水平：中级'));
    expect(prompt, contains('每周 4 次'));
    expect(prompt, contains('器械条件：健身房'));
    expect(prompt, contains('伤病史：膝盖旧伤'));
    expect(prompt, contains('生成 2 周训练计划'));
  });
}
