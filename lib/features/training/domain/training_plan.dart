/// Planner Agent 输出契约（架构 5.1）。JSON 字段保持 snake_case。
class PlanExercise {
  const PlanExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.targetRpe,
    this.safetyNote,
  });

  final String name;
  final int sets;
  final String reps;
  final int restSeconds;
  final double targetRpe;
  final String? safetyNote;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'sets': sets,
    'reps': reps,
    'rest_seconds': restSeconds,
    'target_rpe': targetRpe,
    'safety_note': safetyNote,
  };
}

class PlanSession {
  const PlanSession({
    required this.day,
    required this.focus,
    required this.exercises,
  });

  final String day;
  final String focus;
  final List<PlanExercise> exercises;

  Map<String, Object?> toJson() => <String, Object?>{
    'day': day,
    'focus': focus,
    'exercises': [for (final exercise in exercises) exercise.toJson()],
  };
}

class PlanWeek {
  const PlanWeek({required this.weekNumber, required this.sessions});

  final int weekNumber;
  final List<PlanSession> sessions;

  Map<String, Object?> toJson() => <String, Object?>{
    'week_number': weekNumber,
    'sessions': [for (final session in sessions) session.toJson()],
  };
}

class TrainingPlan {
  const TrainingPlan({required this.weeks, required this.safetyNotes});

  final List<PlanWeek> weeks;
  final String safetyNotes;

  Map<String, Object?> toJson() => <String, Object?>{
    'weeks': [for (final week in weeks) week.toJson()],
    'safety_notes': safetyNotes,
  };
}
