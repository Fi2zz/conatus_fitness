import 'package:flutter/cupertino.dart';

import '../../../app.dart';

/// 训练页顶部：Analysis / Suggestion Agent 入口（架构 3.2）。
class AgentEntries extends StatelessWidget {
  const AgentEntries({super.key});

  @override
  Widget build(BuildContext context) {
    final analysis = _entry(
      context,
      CupertinoIcons.chart_bar,
      '成果分析',
      '训练趋势',
      AppRoutes.analysis,
    );
    final suggestion = _entry(
      context,
      CupertinoIcons.lightbulb,
      '训练建议',
      '下一场训练',
      AppRoutes.suggestionForm,
    );
    final injury = _entry(
      context,
      CupertinoIcons.shield_lefthalf_fill,
      '伤病防护',
      '风险评估',
      AppRoutes.injuryPrevention,
    );
    return Row(
      children: [
        Expanded(child: analysis),
        const SizedBox(width: 8),
        Expanded(child: suggestion),
        const SizedBox(width: 8),
        Expanded(child: injury),
      ],
    );
  }

  Widget _entry(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String route,
  ) {
    return CupertinoButton(
      color: CupertinoColors.tertiarySystemFill,
      padding: const EdgeInsets.all(12),
      onPressed: () =>
          Navigator.of(context, rootNavigator: true).pushNamed(route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: CupertinoColors.activeBlue),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
