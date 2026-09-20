import 'package:conatus/conatus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/app_providers.dart';
import 'agents/planner_agent.dart';
import 'data/event_log_dao.dart';
import 'data/plans_dao.dart';
import 'data/profile_dao.dart';
import 'data/workout_logs_dao.dart';

/// LLM 是否已配置（未配置时 UI 显示引导态，不崩溃）。
final llmReadyProvider = Provider<bool>(
  (ref) => ref.watch(appConfigProvider).llmConfigured,
);

/// 框架 DI 上下文：LLM 等基础设施按 Conatus 惯例注册于此。
final agentContextProvider = Provider<Context>((ref) {
  final context = Context.root(name: 'conatus_fitness');
  ref.onDispose(context.dispose);
  return context;
});

/// 框架 LLM 服务：AppConfig 驱动构造，注册进 Context（'llm'）。
final llmServiceProvider = Provider<LlmProvider?>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.llmConfigured) return null;
  final context = ref.watch(agentContextProvider);
  final doubao = DoubaoProvider(
    apiKey: config.llmApiKey,
    baseUrl: config.llmBaseUrl,
    model: config.llmModel.isEmpty ? null : config.llmModel,
  );
  provideLlm(context, llm: FallbackLlm([doubao]));
  return context.require<LlmProvider>('llm');
});

/// Planner Agent 装配；LLM 未配置时为 null。
final plannerAgentProvider = FutureProvider<PlannerAgent?>((ref) async {
  final llm = ref.watch(llmServiceProvider);
  if (llm == null) return null;
  final db = (await ref.watch(appDatabaseProvider.future)).db;
  return PlannerAgent(
    llm: llm,
    plansDao: PlansDao(db),
    eventLog: EventLogDao(db),
  );
});

/// 单用户画像 DAO（供写入流程使用）。
final profileDaoProvider = FutureProvider<ProfileDao>((ref) async {
  final db = (await ref.watch(appDatabaseProvider.future)).db;
  return ProfileDao(db);
});

/// 单用户画像。
final profileProvider = FutureProvider<UserProfile?>((ref) async {
  final db = (await ref.watch(appDatabaseProvider.future)).db;
  return ProfileDao(db).load();
});

/// 训练日志 DAO（录入与分析共用）。
final workoutLogsDaoProvider = FutureProvider<WorkoutLogsDao>((ref) async {
  final db = (await ref.watch(appDatabaseProvider.future)).db;
  return WorkoutLogsDao(db);
});

/// 历史计划列表（最新在前）。
final plansProvider = FutureProvider<List<StoredPlan>>((ref) async {
  final db = (await ref.watch(appDatabaseProvider.future)).db;
  return PlansDao(db).listLatest();
});

/// 计划详情。
final planDetailProvider = FutureProvider.family<StoredPlan?, String>((
  ref,
  id,
) async {
  final db = (await ref.watch(appDatabaseProvider.future)).db;
  return PlansDao(db).findById(id);
});
