import 'package:flutter/cupertino.dart';

import '../domain/training_plan.dart';

/// 动作行：名称 + 处方（组×次）+ 休息/RPE + 安全注记。
class ExerciseRow extends StatelessWidget {
  const ExerciseRow({super.key, required this.exercise});

  final PlanExercise exercise;

  @override
  Widget build(BuildContext context) {
    final prescription = '${exercise.sets} 组 × ${exercise.reps}';
    final detail =
        '休息 ${exercise.restSeconds} 秒 · RPE ${exercise.targetRpe}';
    final note = exercise.safetyNote;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.label,
                  ),
                ),
              ),
              Text(
                prescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.tertiaryLabel,
            ),
          ),
          if (note != null && note.isNotEmpty)
            Text(
              note,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemOrange,
              ),
            ),
        ],
      ),
    );
  }
}
