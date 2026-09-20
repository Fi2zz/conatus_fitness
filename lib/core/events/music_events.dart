import 'event_envelope.dart';

/// 音乐域事件（架构 4.4）。
sealed class MusicEvent extends AppEvent {
  MusicEvent({required super.sourceAgent, super.trace});
}

/// 用户跳过曲目（负反馈）。
class TrackSkipped extends MusicEvent {
  TrackSkipped({
    required super.sourceAgent,
    required this.trackId,
    required this.context,
    super.trace,
  });

  final String trackId;

  /// 跳过时的训练阶段，如 `warmup` / `working_set` / `rest`。
  final String context;

  @override
  EventPriority get priority => EventPriority.content;
}

/// 用户循环播放（强正反馈）。
class TrackRepeated extends MusicEvent {
  TrackRepeated({required super.sourceAgent, required this.trackId, super.trace});

  final String trackId;

  @override
  EventPriority get priority => EventPriority.content;
}

/// 显式情绪评分。
class MoodFeedback extends MusicEvent {
  MoodFeedback({
    required super.sourceAgent,
    required this.trackId,
    required this.rating,
    super.trace,
  });

  final String trackId;

  /// 1-5 分。
  final int rating;

  @override
  EventPriority get priority => EventPriority.content;
}

/// 训练能量趋势。
class EnergyTrend extends MusicEvent {
  EnergyTrend({
    required super.sourceAgent,
    required this.rising,
    super.trace,
  });

  final bool rising;

  @override
  EventPriority get priority => EventPriority.content;
}
