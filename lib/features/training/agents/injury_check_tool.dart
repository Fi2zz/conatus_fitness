import 'package:conatus/conatus.dart';

import 'plan_safety_rules.dart';

/// 伤病自检工具（ReAct 循环内，模型主动调用）。
///
/// 硬拦截逻辑下沉到工具：冲突时返回结构化失败，模型据此替换动作或补注。
class InjuryCheckTool extends Tool {
  InjuryCheckTool(this.injuries);

  static const toolName = 'injury_check';

  final String injuries;

  @override
  String get name => toolName;

  @override
  String get description =>
      '自检一个动作是否与用户伤病史冲突。生成涉及伤病部位的动作前必须先调用；'
      '冲突时必须替换动作，或说明已做安全处理。';

  @override
  List<ParamSpec> get params => <ParamSpec>[
    ParamSpec.string('exercise', description: '待检查的动作名称', required: true),
  ];

  @override
  Future<ToolResult> call(ToolContext context) async {
    final exercise = context.str('exercise');
    if (exerciseConflictsWith(exercise, injuries, null)) {
      final message = '「$exercise」与伤病史冲突，请替换为安全替代动作';
      return ToolResult.failure(
        message,
        error: ToolError('injury_conflict', message),
      );
    }
    return ToolResult.success('「$exercise」与当前伤病史无冲突');
  }
}
