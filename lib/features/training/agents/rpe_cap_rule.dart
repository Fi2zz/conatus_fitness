import '../../../core/safety/safety_guard.dart';
import '../domain/training_plan.dart';

/// RPE 目标 > 9 → 截断至 9 并加注（架构 14.3.1 的 MVP 简化）。
class RpeCapRule extends SafetyRule<TrainingPlan> {
  const RpeCapRule();

  static const _cap = 9.0;

  @override
  String get name => 'rpe_cap';

  @override
  SafetyVerdict check(TrainingPlan plan) {
    var changed = false;
    final weeks = <PlanWeek>[];
    for (final week in plan.weeks) {
      final sessions = <PlanSession>[];
      for (final session in week.sessions) {
        final exercises = <PlanExercise>[];
        for (final exercise in session.exercises) {
          if (exercise.targetRpe > _cap) {
            changed = true;
            exercises.add(_capped(exercise));
          } else {
            exercises.add(exercise);
          }
        }
        sessions.add(PlanSession(
          day: session.day,
          focus: session.focus,
          exercises: exercises,
        ));
      }
      weeks.add(PlanWeek(weekNumber: week.weekNumber, sessions: sessions));
    }
    if (!changed) return const SafetyPassed();
    return SafetyRewritten(
      TrainingPlan(weeks: weeks, safetyNotes: plan.safetyNotes),
      'RPE 目标超过 9 已截断至 9',
    );
  }

  PlanExercise _capped(PlanExercise exercise) {
    final note = [
      if (exercise.safetyNote != null && exercise.safetyNote!.isNotEmpty)
        exercise.safetyNote!,
      '安全调整：RPE 已从 ${exercise.targetRpe} 截断至 $_cap',
    ].join('；');
    return PlanExercise(
      name: exercise.name,
      sets: exercise.sets,
      reps: exercise.reps,
      restSeconds: exercise.restSeconds,
      targetRpe: _cap,
      safetyNote: note,
    );
  }
}
