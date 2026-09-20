import 'package:conatus_fitness/core/events/agent_event_bus.dart';
import 'package:conatus_fitness/core/events/event_envelope.dart';
import 'package:conatus_fitness/core/events/training_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AppEvent eventOf(AppEvent event) => event;

  test('优先级投递：P0 疲劳事件先于 P2 组完成', () async {
    final bus = AgentEventBus();
    final order = <String>[];

    bus.subscribe<AppEvent>(
      (event) => order.add(event.runtimeType.toString()),
      name: 'order',
    );

    bus.emit(eventOf(SetCompleted(
      sourceAgent: 'test',
      setNumber: 1,
      rpe: 8,
      weight: 100,
      reps: 5,
    )));
    bus.emit(eventOf(FatigueDetected(sourceAgent: 'test', level: 0.9)));

    await Future<void>.delayed(Duration.zero);

    expect(order.first, 'FatigueDetected');
    expect(order, hasLength(2));
  });

  test('订阅者异常隔离：单订阅者连续失败 3 次进死信，不阻塞他人', () async {
    final bus = AgentEventBus();
    var healthyCalls = 0;

    bus.subscribe<AppEvent>(
      (_) => healthyCalls += 1,
      name: 'healthy',
    );
    bus.subscribe<AppEvent>(
      (_) => throw StateError('boom'),
      name: 'broken',
    );

    for (var i = 0; i < 3; i++) {
      bus.emit(eventOf(RestEnded(sourceAgent: 'test')));
    }

    await Future<void>.delayed(Duration.zero);

    expect(healthyCalls, 3);
    expect(bus.deadLetterCount, 1);
  });
}
