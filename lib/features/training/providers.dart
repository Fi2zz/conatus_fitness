import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/event_log_dao.dart';
import '../../di/app_providers.dart';
import '../../di/llm_providers.dart';
import 'agents/planner_agent.dart';
import 'data/plans_dao.dart';
import 'data/profile_dao.dart';
import 'data/workout_logs_dao.dart';

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

/// 训练历史（时间倒序的原始组记录）。
final workoutHistoryProvider = FutureProvider<List<WorkoutSetLog>>((ref) async {
  final dao = await ref.watch(workoutLogsDaoProvider.future);
  return dao.listAll();
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
