import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/events/agent_event_bus.dart';
import '../data/app_database.dart';

/// 运行时配置：密钥经环境/安全存储注入，此处仅持默认值。
final appConfigProvider = Provider<AppConfig>((ref) => const AppConfig());

/// 三域共享的事件总线（架构 9）。
final agentEventBusProvider = Provider<AgentEventBus>((ref) => AgentEventBus());

/// 本地数据库（懒加载打开）。
final appDatabaseProvider = FutureProvider<AppDatabase>(
  (ref) => AppDatabase.open(),
);
