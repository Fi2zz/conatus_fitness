import 'package:uuid/uuid.dart';

/// 事件优先级（架构 9.1.2），同级 FIFO。
enum EventPriority {
  /// P0 安全类：FatigueDetected(高) 等。
  safety,

  /// P1 用户指令类：AsrFinal、IntentRecognized、WakeWordDetected。
  userCommand,

  /// P2 训练状态类：SetCompleted、Rest 系列等。
  trainingState,

  /// P3 内容类：TrackSkipped、MoodFeedback、AsrPartial。
  content,
}

/// 所有事件的公共信封（架构 9.1.4）：
/// 附带 eventId、timestamp、sourceAgent、traceId，供事件溯源与回放。
abstract class AppEvent {
  AppEvent({
    String? eventId,
    DateTime? timestamp,
    required this.sourceAgent,
    String? trace,
  }) : eventId = eventId ?? _uuid.v4(),
       timestamp = timestamp ?? DateTime.now() {
    traceId = trace ?? this.eventId;
  }

  static final Uuid _uuid = Uuid();

  final String eventId;
  final DateTime timestamp;

  /// 产出事件的 Agent 标识，如 `training.dj`。
  final String sourceAgent;

  /// 同一次训练/交互链路共享的追踪 id，默认独立成链。
  late final String traceId;

  /// 投递优先级，子类按语义覆写。
  EventPriority get priority => EventPriority.content;
}
