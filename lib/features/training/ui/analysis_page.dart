import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tools/tool.dart';
import '../../common/app_dialogs.dart';
import '../../common/domain_placeholder.dart';
import '../agent_providers.dart';

/// 成果分析页（架构 5.2）：ReAct 分析训练日志，结论为文本。
class AnalysisPage extends ConsumerStatefulWidget {
  const AnalysisPage({super.key});

  @override
  ConsumerState<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends ConsumerState<AnalysisPage> {
  String? _conclusion;

  @override
  Widget build(BuildContext context) {
    final runButton = Padding(
      padding: const EdgeInsets.all(16),
      child: CupertinoButton.filled(onPressed: _run, child: const Text('开始分析')),
    );
    final conclusion = _conclusion;
    final body = conclusion == null
        ? const DomainPlaceholder(
            icon: CupertinoIcons.chart_bar,
            title: '成果分析',
            subtitle: '基于训练日志生成「事实 → 解读 → 下一步」',
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                conclusion,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ],
          );
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('成果分析')),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: body),
            runButton,
          ],
        ),
      ),
    );
  }

  Future<void> _run() async {
    final agent = await ref.read(analysisAgentProvider.future);
    if (!mounted) return;
    if (agent == null) {
      await showAppAlert(context, 'LLM 未配置，请检查启动参数');
      return;
    }
    showAppProgress(context, title: '正在分析');
    final result = await agent.analyze();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // 关闭进度弹窗
    switch (result) {
      case Ok(:final value):
        setState(() => _conclusion = value);
      case RetryableError(:final message):
        await showAppAlert(context, message);
      case FatalError(:final message, :final suggestion):
        await showAppAlert(
          context,
          suggestion == null ? message : '$message\n$suggestion',
        );
    }
  }
}
