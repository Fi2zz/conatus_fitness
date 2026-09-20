import 'package:flutter/cupertino.dart';

import '../domain/training_plan.dart';
import 'exercise_row.dart';

/// 单次训练卡片：日/焦点标题 + 动作明细。
class SessionCard extends StatelessWidget {
  const SessionCard({super.key, required this.session});

  final PlanSession session;

  @override
  Widget build(BuildContext context) {
    final title = '${session.day} · ${session.focus}';
    final exerciseRows = <Widget>[
      for (final exercise in session.exercises) ExerciseRow(exercise: exercise),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 8),
          ...exerciseRows,
        ],
      ),
    );
  }
}
