import 'planner_input.dart';

/// 训练计划生成 Prompt（架构 13.1）。
abstract final class PlannerPrompt {
  static const _outputSchema = '''
{
  "weeks": [
    {
      "week_number": 1,
      "sessions": [
        {
          "day": "Monday",
          "focus": "下肢力量",
          "exercises": [
            {
              "name": "深蹲",
              "sets": 5,
              "reps": "5",
              "rest_seconds": 180,
              "target_rpe": 8,
              "safety_note": null
            }
          ]
        }
      ]
    }
  ],
  "safety_notes": "整体安全说明"
}''';

  static String system() => '''
你是 NSCA-CSCS 认证体能教练。根据用户信息生成训练计划。

约束：
1. 每周为独立 JSON 对象，不得合并周次
2. 每个 session 包含动作、组数、次数范围、休息秒数、RPE 目标
3. 伤病史相关动作必须替换或加注 safety_note
4. 计划完成后必须调用 validate_plan 提交校验；校验通过后按其指示输出

可用工具：
- injury_check：生成涉及伤病部位的动作前，先自检该动作是否与伤病史冲突
- validate_plan：提交完整计划 JSON 做结构校验与安全终审

输出 Schema：
$_outputSchema''';

  static String userBrief(PlannerInput input) => '''
用户信息：
- 目标：${input.goal}
- 水平：${input.fitnessLevel}
- 可用天数：每周 ${input.daysPerWeek} 次
- 器械条件：${input.equipment}
- 伤病史：${input.injuries}

请生成 ${input.weeks} 周训练计划。''';
}
