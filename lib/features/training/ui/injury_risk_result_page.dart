import 'package:flutter/cupertino.dart';

import '../domain/injury_risk_report.dart';

/// 伤病风险报告结果页。
class InjuryRiskResultPage extends StatelessWidget {
  const InjuryRiskResultPage({super.key, required this.report});

  final InjuryRiskReport report;

  static const _levelLabels = <String, String>{
    'low': '低',
    'medium': '中',
    'high': '高',
  };

  @override
  Widget build(BuildContext context) {
    final levelLabel = _levelLabels[report.riskLevel] ?? report.riskLevel;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('伤病风险报告')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _tile('风险等级', levelLabel),
            _tile('风险部位', report.riskAreas.join('、')),
            _tile('负荷分析', report.loadAnalysis),
            _listTile('风险动作', report.conflictingExercises),
            _listTile('安全替代', report.safeAlternatives),
            _listTile('防护建议', report.preventiveActions),
          ],
        ),
      ),
    );
  }

  Widget _tile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }

  Widget _listTile(String title, List<String> items) {
    return _tile(title, items.isEmpty ? '—' : items.map((item) => '· $item').join('\n'));
  }
}
