import 'dart:async';
import 'dart:collection';

import 'event_envelope.dart';

/// 背压策略（架构 9.1.1）。
enum Backpressure {
  /// 只保留最新值：AsrPartial、EnergyTrend 等状态流事件。
  latest,

  /// 每订阅者独立队列（默认容量 32），溢出丢最旧并告警。
  buffer,
}

/// 单个订阅者的投递通道：独立队列 + 异常隔离（架构 9.1.3）。
class EventSubscriber {
  EventSubscriber({
    required this.name,
    required this.matches,
    required this.invoke,
    this.backpressure = Backpressure.buffer,
    this.capacity = 32,
    this.onFatal,
  });

  static const int maxConsecutiveFailures = 3;

  final String name;
  final Backpressure backpressure;
  final int capacity;

  /// 类型/业务过滤。
  final bool Function(AppEvent) matches;

  /// 处理体。
  final void Function(AppEvent) invoke;

  /// 连续失败达上限时回调（总线负责进死信队列）。
  final void Function(AppEvent event, Object error)? onFatal;

  final Queue<AppEvent> _pending = Queue<AppEvent>();
  bool _draining = false;
  int _consecutiveFailures = 0;

  bool accepts(AppEvent event) => matches(event);

  /// 入队（带背压），并确保异步排空。
  void enqueue(AppEvent event, void Function(String message) onDropped) {
    switch (backpressure) {
      case Backpressure.latest:
        _pending
          ..clear()
          ..add(event);
      case Backpressure.buffer:
        if (_pending.length >= capacity) {
          _pending.removeFirst();
          onDropped('[$name] 队列溢出，丢弃最旧事件');
        }
        _pending.add(event);
    }
    _scheduleDrain();
  }

  void _scheduleDrain() {
    if (_draining) return;
    _draining = true;
    scheduleMicrotask(_drain);
  }

  void _drain() {
    while (_pending.isNotEmpty) {
      final event = _pending.removeFirst();
      try {
        invoke(event);
        _consecutiveFailures = 0;
      } catch (error) {
        _consecutiveFailures += 1;
        if (_consecutiveFailures >= maxConsecutiveFailures) {
          _consecutiveFailures = 0;
          onFatal?.call(event, error);
        }
      }
    }
    _draining = false;
  }
}
