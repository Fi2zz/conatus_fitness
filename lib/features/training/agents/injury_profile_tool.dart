import 'package:conatus/conatus.dart';

import '../data/profile_dao.dart';

/// 画像读取工具：向模型暴露伤病史等画像信息。
class InjuryProfileTool extends Tool {
  InjuryProfileTool(this.dao);

  static const toolName = 'injury_profile';

  final ProfileDao dao;

  @override
  String get name => toolName;

  @override
  String get description => '读取用户画像与伤病史。评估任何伤病风险前必须先调用。';

  @override
  List<ParamSpec> get params => const <ParamSpec>[];

  @override
  Future<ToolResult> call(ToolContext context) async {
    final profile = await dao.load();
    if (profile == null) {
      return ToolResult.success('用户尚未填写画像（无伤病史记录）。请基于此保守评估');
    }
    return ToolResult.success(
      '画像：目标=${profile.goal}，水平=${profile.fitnessLevel}，'
      '每周 ${profile.daysPerWeek} 次，器械=${profile.equipment}，'
      '伤病史=${profile.injuries.isEmpty ? '无' : profile.injuries}',
    );
  }
}
