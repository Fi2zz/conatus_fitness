import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tools/tool.dart';
import '../../common/app_dialogs.dart';
import '../agents/planner_input.dart';
import '../data/profile_dao.dart';
import '../providers.dart';
import '../../../app.dart';

/// 生成流程：调用 PlannerAgent → 结果处理（导航/提示/画像落库）。
Future<void> generatePlan(
  BuildContext context,
  WidgetRef ref,
  PlannerInput input,
) async {
  final agent = await ref.read(plannerAgentProvider.future);
  if (!context.mounted) return;
  if (agent == null) {
    await showAppAlert(context, 'LLM 未配置，请检查启动参数');
    return;
  }
  showAppProgress(context);
  final result = await agent.generate(input);
  if (!context.mounted) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  navigator.pop(); // 关闭进度弹窗
  switch (result) {
    case Ok(:final value):
      await _saveProfile(ref, input);
      ref.invalidate(plansProvider);
      ref.invalidate(profileProvider);
      navigator.pop(); // 关闭设置页
      navigator.pushNamed(AppRoutes.planDetail, arguments: value.id);
    case RetryableError(:final message):
      await showAppAlert(context, message);
    case FatalError(:final message, :final suggestion):
      await showAppAlert(context, suggestion == null ? message : '$message\n$suggestion');
  }
}

Future<void> _saveProfile(WidgetRef ref, PlannerInput input) async {
  final dao = await ref.read(profileDaoProvider.future);
  await dao.save(UserProfile(
    goal: input.goal,
    fitnessLevel: input.fitnessLevel,
    daysPerWeek: input.daysPerWeek,
    equipment: input.equipment,
    injuries: input.injuries,
  ));
}
