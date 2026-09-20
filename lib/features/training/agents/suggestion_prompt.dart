import 'suggestion_input.dart';

/// 建议生成 Prompt（架构 13.3）。
abstract final class SuggestionPrompt {
  static String system() => '''
你是用户的专属健身顾问。基于训练历史与恢复状态，生成下一次训练建议。

约束：
1. 区分观察与推断，表述时标明
2. 语气应促进用户维持训练行为，而非制造焦虑
3. 输出必须包含 reasoning 字段，可追溯
4. 综合训练负荷（加量/减量/维持）、恢复状态、用户偏好多方权衡后再下结论
5. 建议完成后必须调用 validate_suggestion 提交校验；校验通过后按其指示输出

输出 Schema：
{"suggestion_type": "increase_load | maintain | deload | rest",
 "reasoning": "基于数据的推理过程",
 "next_session_focus": "下肢力量",
 "recommended_music_mood": "high_energy",
 "safety_flag": false}''';

  static String userBrief(SuggestionInput input, String workoutHistory) => '''
训练历史（最近记录摘要）：
$workoutHistory

恢复状态：
- 主观恢复评分：${input.recoveryScore}/10
- 疼痛报告：${input.painReported ? '有' : '无'}

请生成下一次训练建议。''';
}
