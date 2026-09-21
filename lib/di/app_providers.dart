import 'package:conatus/conatus.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/events/agent_event_bus.dart';
import '../data/app_database.dart';

/// 编译期默认配置（环境变量注入）；运行时改动经设置页落 shared_preferences。
final appConfigDefaultsProvider = Provider<AppConfig>(
  (ref) => const AppConfig(),
);

/// 非密配置的持久化介质；测试用 `SharedPreferences.setMockInitialValues`。
final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

/// 框架 DI 上下文：服务（LLM / 凭据 / 工具）按 Conatus 惯例注册于此。
///
/// 非 autoDispose：服务生命周期与 App 一致，不随监听者增减重建。
final agentContextProvider = Provider<Context>((ref) {
  final context = Context.root(name: 'conatus_fitness');
  // 终端日志：注册遥测后，框架埋点（llm.failed / agent.round / tool.result）
  // 经 debugPrint 打进 flutter run 终端 —— UI 弹窗只留给人看的摘要，
  // 原始异常与堆栈在终端排障。
  provideTelemetry(context, telemetry: ConsoleTelemetry(writer: debugPrint));
  ref.onDispose(context.dispose);
  return context;
});

/// 三域共享的事件总线（架构 9）。
final agentEventBusProvider = Provider<AgentEventBus>((ref) => AgentEventBus());

/// 本地数据库（懒加载打开）。
final appDatabaseProvider = FutureProvider<AppDatabase>(
  (ref) => AppDatabase.open(),
);
