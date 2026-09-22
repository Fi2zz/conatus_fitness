import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/agents/agent_outcome.dart';
import '../../../app.dart';
import '../../common/app_dialogs.dart';
import '../../common/domain_placeholder.dart';
import '../agent_providers.dart';

/// 伤病防护页：ReAct 评估伤病史与训练负荷，输出风险报告。
class InjuryPreventionPage extends ConsumerWidget {
  const InjuryPreventionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('伤病防护'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(AppRoutes.injuryRecords),
          child: const Icon(CupertinoIcons.pencil),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Expanded(
              child: DomainPlaceholder(
                icon: CupertinoIcons.shield_lefthalf_fill,
                title: '伤病风险评估',
                subtitle: '结合伤病史与近期负荷，输出风险报告与防护建议',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoButton.filled(
                onPressed: () => _run(context, ref),
                child: const Text('开始评估'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref) async {
    final agent = await ref.read(injuryPreventionAgentProvider.future);
    if (!context.mounted) return;
    if (agent == null) {
      await showAppAlert(context, 'LLM 未配置，请检查启动参数');
      return;
    }
    showAppProgress(context, title: '正在评估风险');
    final result = await agent.evaluate();
    if (!context.mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pop(); // 关闭进度弹窗
    switch (result) {
      case Ok(:final value):
        navigator.pushNamed(AppRoutes.injuryPreventionResult, arguments: value);
      case RetryableError(:final message):
        await showAppAlert(context, message);
      case FatalError(:final message, :final suggestion):
        final alert = suggestion == null ? message : '$message\n$suggestion';
        await showAppAlert(context, alert);
    }
  }
}
