import 'package:conatus/conatus.dart';

/// 恢复信号工具（架构 5.2）MVP：主观恢复评分数据源未接入，如实返回数据不足。
class RecoverySignalTool extends Tool {
  const RecoverySignalTool();

  static const toolName = 'recovery_signal';

  @override
  String get name => toolName;

  @override
  String get description => '获取主观恢复评分趋势。当前无评分数据源，调用将返回数据不足提示。';

  @override
  List<ParamSpec> get params => const <ParamSpec>[];

  @override
  Future<ToolResult> call(ToolContext context) async {
    return ToolResult.success(
      '数据不足：暂无主观恢复评分记录。'
      '请在结论中注明"恢复状态数据不足"，'
      '可基于 RPE 与容量趋势谨慎推断，不得编造评分。',
    );
  }
}
