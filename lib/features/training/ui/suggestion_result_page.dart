import 'package:flutter/cupertino.dart';

import '../domain/training_suggestion.dart';

/// 训练建议结果页（架构 5.3 输出结构）。
class SuggestionResultPage extends StatelessWidget {
  const SuggestionResultPage({super.key, required this.suggestion});

  final TrainingSuggestion suggestion;

  static const _typeLabels = <String, String>{
    'increase_load': '加量',
    'maintain': '维持',
    'deload': '减量',
    'rest': '休息',
  };

  @override
  Widget build(BuildContext context) {
    final typeLabel = _typeLabels[suggestion.suggestionType] ?? suggestion.suggestionType;
    final focus = suggestion.nextSessionFocus;
    final mood = suggestion.recommendedMusicMood;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('下次训练建议')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _tile('建议类型', typeLabel),
            _tile('下次训练重点', focus.isEmpty ? '—' : focus),
            _tile('推荐音乐氛围', mood.isEmpty ? '—' : mood),
            if (suggestion.safetyFlag) _safetyBanner(),
            _tile('推理过程', suggestion.reasoning),
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

  Widget _safetyBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemYellow.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        '安全提示：本建议已经过安全规则调整，请注意身体信号',
        style: TextStyle(fontSize: 13),
      ),
    );
  }
}
