import 'package:flutter_test/flutter_test.dart';

import 'package:conatus_fitness/core/safety/safety_guard.dart';
import 'package:conatus_fitness/features/training/agents/plan_safety_rules.dart';
import 'package:conatus_fitness/features/training/agents/rpe_cap_rule.dart';
import 'package:conatus_fitness/features/training/domain/training_plan.dart';

TrainingPlan planWith(List<PlanExercise> exercises) => TrainingPlan(
  weeks: [
    PlanWeek(
      weekNumber: 1,
      sessions: [PlanSession(day: 'Monday', focus: '下肢', exercises: exercises)],
    ),
  ],
  safetyNotes: '',
);

void main() {
  test('伤病动作未加注 → 拦截', () {
    final rule = InjuryMovementRule('膝盖旧伤');
    final plan = planWith([
      const PlanExercise(
        name: '深蹲',
        sets: 5,
        reps: '5',
        restSeconds: 180,
        targetRpe: 8,
      ),
    ]);
    final verdict = rule.check(plan);
    expect(verdict, isA<SafetyBlocked>());
  });

  test('伤病动作已加注 → 通过', () {
    final rule = InjuryMovementRule('膝盖旧伤');
    final plan = planWith([
      const PlanExercise(
        name: '深蹲',
        sets: 5,
        reps: '5',
        restSeconds: 180,
        targetRpe: 8,
        safetyNote: '已替换为箱式深蹲，深度减半',
      ),
    ]);
    expect(rule.check(plan), isA<SafetyPassed>());
  });

  test('无伤病 → 通过', () {
    final rule = InjuryMovementRule('无');
    final plan = planWith([
      const PlanExercise(
        name: '深蹲',
        sets: 5,
        reps: '5',
        restSeconds: 180,
        targetRpe: 8,
      ),
    ]);
    expect(rule.check(plan), isA<SafetyPassed>());
  });

  test('RPE 超标 → 改写并加注', () {
    const rule = RpeCapRule();
    final verdict = rule.check(
      planWith([
        const PlanExercise(
          name: '卧推',
          sets: 5,
          reps: '5',
          restSeconds: 180,
          targetRpe: 9.5,
        ),
      ]),
    );
    expect(verdict, isA<SafetyRewritten>());
    final rewritten = (verdict as SafetyRewritten<TrainingPlan>).rewritten;
    final exercise = rewritten.weeks.first.sessions.first.exercises.first;
    expect(exercise.targetRpe, 9);
    expect(exercise.safetyNote, contains('截断至 9'));
  });

  test('RPE 正常 → 原样通过', () {
    const rule = RpeCapRule();
    final plan = planWith([
      const PlanExercise(
        name: '卧推',
        sets: 5,
        reps: '5',
        restSeconds: 180,
        targetRpe: 8,
      ),
    ]);
    expect(rule.check(plan), isA<SafetyPassed>());
  });
}
