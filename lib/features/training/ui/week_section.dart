import 'package:flutter/cupertino.dart';

import '../domain/training_plan.dart';
import 'session_card.dart';

/// 单周区块：周标题 + 该周全部训练卡片。
class WeekSection extends StatelessWidget {
  const WeekSection({super.key, required this.week});

  final PlanWeek week;

  @override
  Widget build(BuildContext context) {
    final header = '第 ${week.weekNumber} 周';
    final sessionCards = <Widget>[
      for (final session in week.sessions) SessionCard(session: session),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            header,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
        ),
        ...sessionCards,
      ],
    );
  }
}
