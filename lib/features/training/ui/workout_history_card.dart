import 'package:flutter/cupertino.dart';

import '../../../core/format/date_text.dart';
import '../agents/analysis_stats.dart';
import '../data/workout_session.dart';

/// 历史训练课卡片：日期 + 各动作摘要。
class WorkoutHistoryCard extends StatelessWidget {
  const WorkoutHistoryCard({super.key, required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final lines = [
      for (final entry in byExercise(session.sets))
        '${entry.key} ${entry.value.sets} 组 · 容量 ${entry.value.totalVolume.toStringAsFixed(0)}kg',
    ];
    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          dateText(session.performedAt),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        Text(
          '${session.setCount} 组',
          style: const TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
        ),
      ],
    );
    final details = [
      for (final line in lines)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(line, style: const TextStyle(fontSize: 13)),
        ),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, ...details],
      ),
    );
  }
}
