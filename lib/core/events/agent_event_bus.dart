import 'dart:async';
import 'dart:collection';

import '../logging/app_log.dart';
import 'event_envelope.dart';
import 'event_subscriber.dart';

/// 跨域事件总线（架构 9）。
///
/// * 优先级投递，同级 FIFO（9.1.2）；
/// * 订阅者独立队列 + 异常隔离，连续失败 3 次进死信（9.1.3）；
/// * 死信保留在内存，供诊断界面查看（落盘由 event_log 表负责）。
class AgentEventBus {
  final SplayTreeMap<int, Queue<AppEvent>> _queues = SplayTreeMap();
  final List<EventSubscriber> _subscribers = [];
  final List<({AppEvent event, Object error, DateTime at})> _deadLetters = [];
  bool _dispatching = false;

  int get deadLetterCount => _deadLetters.length;
  List<({AppEvent event, Object error, DateTime at})> get deadLetters =>
      List.unmodifiable(_deadLetters);

  // ---- 发布 ----

  /// 按优先级入队并触发异步投递。
  void emit(AppEvent event) {
    final queue = _queues.putIfAbsent(
      event.priority.index,
      () => Queue<AppEvent>(),
    );
    queue.add(event);
    _scheduleDispatch();
  }

  // ---- 订阅 ----

  /// 订阅特定事件类型（含子类）。
  void subscribe<T extends AppEvent>(
    void Function(T event) handler, {
    String name = 'subscriber',
    Backpressure backpressure = Backpressure.buffer,
  }) {
    _subscribers.add(
      EventSubscriber(
        name: name,
        matches: (event) => event is T,
        invoke: (event) => handler(event as T),
        backpressure: backpressure,
        onFatal: _recordDeadLetter,
      ),
    );
  }

  /// 以流的形式消费（内部仍走优先级队列与背压）。
  Stream<T> on<T extends AppEvent>({
    Backpressure backpressure = Backpressure.buffer,
  }) {
    final controller = StreamController<T>();
    late final EventSubscriber subscriber;
    subscriber = EventSubscriber(
      name: 'stream<$T>',
      matches: (event) => event is T,
      invoke: (event) {
        if (!controller.isClosed) controller.add(event as T);
      },
      backpressure: backpressure,
      onFatal: _recordDeadLetter,
    );
    _subscribers.add(subscriber);
    controller.onCancel = () => _subscribers.remove(subscriber);
    return controller.stream;
  }

  /// 取消具名订阅。
  void unsubscribe(String name) {
    _subscribers.removeWhere((sub) => sub.name == name);
  }

  // ---- 投递循环 ----

  void _scheduleDispatch() {
    if (_dispatching) return;
    _dispatching = true;
    scheduleMicrotask(_dispatch);
  }

  void _dispatch() {
    while (_queues.isNotEmpty) {
      final firstKey = _queues.firstKey()!;
      final event = _queues[firstKey]!.removeFirst();
      if (_queues[firstKey]!.isEmpty) _queues.remove(firstKey);
      for (final subscriber in _subscribers) {
        if (!subscriber.accepts(event)) continue;
        subscriber.enqueue(event, _warnDropped);
      }
    }
    _dispatching = false;
  }

  void _warnDropped(String message) => AppLog.warn('event_bus', message);

  void _recordDeadLetter(AppEvent event, Object error) {
    _deadLetters.add((event: event, error: error, at: DateTime.now()));
    AppLog.error('event_bus', '${event.eventId} 进入死信队列', error);
  }
}
