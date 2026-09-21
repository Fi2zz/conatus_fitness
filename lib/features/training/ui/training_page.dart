import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app.dart';
import '../../../di/llm_providers.dart';
import '../../common/domain_placeholder.dart';
import '../data/plans_dao.dart';
import '../providers.dart';
import 'agent_entries.dart';
import 'plan_card.dart';

/// 训练域首页（Phase 1）：AI 训练计划列表 + 生成入口。
class TrainingPage extends ConsumerWidget {
  const TrainingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = switch (ref.watch(llmStatusProvider)) {
      // 读盘期与内容加载同形（转圈），避免启动时闪引导态。
      LlmStatus.loading => const Center(child: CupertinoActivityIndicator()),
      LlmStatus.notConfigured => const DomainPlaceholder(
        icon: CupertinoIcons.lock_circle,
        title: 'AI 训练计划',
        subtitle: '在「我的 → 模型接入」填好 Base URL 与 API Key 后即可使用',
      ),
      LlmStatus.ready => _plansBody(context, ref),
    };
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('训练'),
        automaticallyImplyLeading: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _navAction(context, CupertinoIcons.clock, AppRoutes.workoutHistory),
            _navAction(
              context,
              CupertinoIcons.plus_square,
              AppRoutes.logWorkout,
            ),
            _navAction(context, CupertinoIcons.add, AppRoutes.planSetup),
          ],
        ),
      ),
      child: SafeArea(child: body),
    );
  }

  Widget _navAction(BuildContext context, IconData icon, String route) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () =>
          Navigator.of(context, rootNavigator: true).pushNamed(route),
      child: Icon(icon),
    );
  }
}

Widget _plansBody(BuildContext context, WidgetRef ref) {
  final plans = ref.watch(plansProvider);
  return plans.when(
    loading: () => const Center(child: CupertinoActivityIndicator()),
    error: (error, _) => const DomainPlaceholder(
      icon: CupertinoIcons.exclamationmark_triangle,
      title: 'AI 训练计划',
      subtitle: '数据加载失败，请重启应用重试',
    ),
    data: (items) => _list(context, items),
  );
}

Widget _list(BuildContext context, List<StoredPlan> items) {
  final entries = const Padding(
    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: AgentEntries(),
  );
  final list = items.isEmpty
      ? const DomainPlaceholder(
          icon: CupertinoIcons.flame,
          title: 'AI 训练计划',
          subtitle: '基于你的画像与历史，生成个性化周计划',
        )
      : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) => PlanCard(stored: items[index]),
        );
  return Column(
    children: [
      entries,
      Expanded(child: list),
    ],
  );
}
