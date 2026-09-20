import 'dart:async';

import '../events/agent_event_bus.dart';
import '../events/event_envelope.dart';

/// 事件驱动型 Agent 基类（架构 4.2）。
///
/// 契约：`handle` 为本地规则路径，必须亚秒级返回（DJ < 200ms）；
/// 需要 LLM 的重决策应在 handle 内触发异步任务，不得阻塞事件循环。
abstract class ReactiveAgent {
  ReactiveAgent(this.bus, {required this.name});

  final AgentEventBus bus;
  final String name;

  /// 是否处理该事件（类型过滤 + 业务过滤）。
  bool handles(AppEvent event);

  /// 本地规则处理路径。实现必须快速返回、不抛异常。
  void handle(AppEvent event);

  StreamSubscription<AppEvent>? _subscription;

  void start() {
    _subscription ??= bus.on<AppEvent>().listen((event) {
      if (!handles(event)) return;
      try {
        handle(event);
      } catch (error) {
        onHandlerError(event, error);
      }
    }, cancelOnError: false);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// 处理异常兜底：默认忽略（总线级死信由订阅通道负责）。
  void onHandlerError(AppEvent event, Object error) {}
}
