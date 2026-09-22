import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app.dart';
import '../../../core/agents/agent_outcome.dart';
import '../../common/app_dialogs.dart';
import '../agent_providers.dart';
import '../agents/suggestion_input.dart';

/// 训练建议表单页（架构 5.3 MVP）：主观恢复信号输入。
class SuggestionFormPage extends ConsumerStatefulWidget {
  const SuggestionFormPage({super.key});

  @override
  ConsumerState<SuggestionFormPage> createState() => _SuggestionFormPageState();
}

class _SuggestionFormPageState extends ConsumerState<SuggestionFormPage> {
  double _score = 5;
  bool _pain = false;

  @override
  Widget build(BuildContext context) {
    final slider = CupertinoSlider(
      value: _score,
      min: 0,
      max: 10,
      divisions: 10,
      onChanged: (value) => setState(() => _score = value),
    );
    final painRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('是否有疼痛', style: TextStyle(fontSize: 15)),
        CupertinoSwitch(
          value: _pain,
          onChanged: (value) => setState(() => _pain = value),
        ),
      ],
    );
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('训练建议')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '主观恢复评分',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const Text(
              '0 = 精疲力尽，10 = 状态拉满',
              style: TextStyle(color: CupertinoColors.secondaryLabel),
            ),
            slider,
            Center(child: Text('${_score.round()} / 10')),
            const SizedBox(height: 24),
            painRow,
            const SizedBox(height: 32),
            CupertinoButton.filled(
              onPressed: _submit,
              child: const Text('生成建议'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final agent = await ref.read(suggestionAgentProvider.future);
    if (!mounted) return;
    if (agent == null) {
      await showAppAlert(context, 'LLM 未配置，请检查启动参数');
      return;
    }
    showAppProgress(context, title: '正在生成建议');
    final input = SuggestionInput(
      recoveryScore: _score.round(),
      painReported: _pain,
    );
    final result = await agent.suggest(input);
    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pop(); // 关闭进度弹窗
    switch (result) {
      case Ok(:final value):
        navigator.pushNamed(AppRoutes.suggestionResult, arguments: value);
      case RetryableError(:final message):
        await showAppAlert(context, message);
      case FatalError(:final message, :final suggestion):
        final alert = suggestion == null ? message : '$message\n$suggestion';
        await showAppAlert(context, alert);
    }
  }
}
