import 'event_envelope.dart';

/// 训练域事件（架构 4.4）。
sealed class TrainingEvent extends AppEvent {
  TrainingEvent({required super.sourceAgent, super.trace});
}

/// 一组训练完成。
class SetCompleted extends TrainingEvent {
  SetCompleted({
    required super.sourceAgent,
    required this.setNumber,
    required this.rpe,
    required this.weight,
    required this.reps,
    super.trace,
  });

  final int setNumber;
  final double rpe;
  final double weight;
  final int reps;

  @override
  EventPriority get priority => EventPriority.trainingState;
}

/// 组间休息开始。
class RestStarted extends TrainingEvent {
  RestStarted({
    required super.sourceAgent,
    required this.durationSeconds,
    required this.intensity,
    super.trace,
  });

  final int durationSeconds;

  /// 休息强度 0-1，供 DJ 调整音乐。
  final double intensity;

  @override
  EventPriority get priority => EventPriority.trainingState;
}

/// 组间休息结束。
class RestEnded extends TrainingEvent {
  RestEnded({required super.sourceAgent, super.trace});

  @override
  EventPriority get priority => EventPriority.trainingState;
}

/// 一次训练开始。
class WorkoutStarted extends TrainingEvent {
  WorkoutStarted({
    required super.sourceAgent,
    required this.planId,
    required this.focus,
    super.trace,
  });

  final String planId;
  final String focus;

  @override
  EventPriority get priority => EventPriority.trainingState;
}

/// 一次训练结束。
class WorkoutEnded extends TrainingEvent {
  WorkoutEnded({
    required super.sourceAgent,
    required this.totalVolume,
    required this.durationSeconds,
    super.trace,
  });

  final double totalVolume;
  final int durationSeconds;

  @override
  EventPriority get priority => EventPriority.trainingState;
}

/// 疲劳信号；level >= 0.8 时升级为 P0（架构 9.1.2）。
class FatigueDetected extends TrainingEvent {
  FatigueDetected({required super.sourceAgent, required this.level, super.trace});

  final double level;

  @override
  EventPriority get priority =>
      level >= 0.8 ? EventPriority.safety : EventPriority.trainingState;
}

/// 刷新个人纪录。
class PersonalRecord extends TrainingEvent {
  PersonalRecord({
    required super.sourceAgent,
    required this.lift,
    required this.weight,
    super.trace,
  });

  final String lift;
  final double weight;

  @override
  EventPriority get priority => EventPriority.trainingState;
}

/// PR 尝试（关键事件，投递不允许丢弃）。
class PersonalRecordAttempt extends TrainingEvent {
  PersonalRecordAttempt({
    required super.sourceAgent,
    required this.lift,
    required this.weight,
    super.trace,
  });

  final String lift;
  final double weight;

  @override
  EventPriority get priority => EventPriority.trainingState;
}

/// 平台期检出。
class PlateauDetected extends TrainingEvent {
  PlateauDetected({required super.sourceAgent, required this.exercise, super.trace});

  final String exercise;

  @override
  EventPriority get priority => EventPriority.trainingState;
}
