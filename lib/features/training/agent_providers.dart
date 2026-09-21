import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/event_log_dao.dart';
import '../../di/app_providers.dart';
import '../../di/llm_providers.dart';
import 'agents/analysis_agent.dart';
import 'agents/injury_prevention_agent.dart';
import 'agents/suggestion_agent.dart';
import 'data/agent_memory_dao.dart';
import 'data/profile_dao.dart';
import 'data/workout_logs_dao.dart';

/// Injury Prevention Agent 装配（ReAct）；LLM 未配置时为 null。
final injuryPreventionAgentProvider = FutureProvider<InjuryPreventionAgent?>((
  ref,
) async {
  if (ref.watch(llmStatusProvider) != LlmStatus.ready) return null;
  final ctx = ref.watch(agentContextProvider);
  final db = (await ref.watch(appDatabaseProvider.future)).db;
  return InjuryPreventionAgent(
    ctx: ctx,
    logsDao: WorkoutLogsDao(db),
    profileDao: ProfileDao(db),
    memoryDao: AgentMemoryDao(db),
    eventLog: EventLogDao(db),
  );
});

/// Analysis Agent 装配（架构 5.2）；LLM 未配置时为 null。
final analysisAgentProvider = FutureProvider<AnalysisAgent?>((ref) async {
  if (ref.watch(llmStatusProvider) != LlmStatus.ready) return null;
  final ctx = ref.watch(agentContextProvider);
  final db = (await ref.watch(appDatabaseProvider.future)).db;
  return AnalysisAgent(
    ctx: ctx,
    logsDao: WorkoutLogsDao(db),
    memoryDao: AgentMemoryDao(db),
    eventLog: EventLogDao(db),
  );
});

/// Suggestion Agent 装配（架构 5.3）；LLM 未配置时为 null。
final suggestionAgentProvider = FutureProvider<SuggestionAgent?>((ref) async {
  if (ref.watch(llmStatusProvider) != LlmStatus.ready) return null;
  final ctx = ref.watch(agentContextProvider);
  final db = (await ref.watch(appDatabaseProvider.future)).db;
  return SuggestionAgent(
    ctx: ctx,
    logsDao: WorkoutLogsDao(db),
    memoryDao: AgentMemoryDao(db),
    eventLog: EventLogDao(db),
  );
});
