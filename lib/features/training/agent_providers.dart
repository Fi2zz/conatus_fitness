import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/app_providers.dart';
import 'agents/analysis_agent.dart';
import 'agents/injury_prevention_agent.dart';
import 'agents/suggestion_agent.dart';
import 'data/agent_memory_dao.dart';
import 'data/event_log_dao.dart';
import 'data/profile_dao.dart';
import 'data/workout_logs_dao.dart';
import 'providers.dart';

/// Injury Prevention Agent 装配（ReAct）；LLM 未配置时为 null。
final injuryPreventionAgentProvider = FutureProvider<InjuryPreventionAgent?>((
  ref,
) async {
  final llm = ref.watch(llmServiceProvider);
  if (llm == null) return null;
  final db = (await ref.watch(appDatabaseProvider.future)).db;
  return InjuryPreventionAgent(
    llm: llm,
    logsDao: WorkoutLogsDao(db),
    profileDao: ProfileDao(db),
    memoryDao: AgentMemoryDao(db),
    eventLog: EventLogDao(db),
  );
});

/// Analysis Agent 装配（架构 5.2）；LLM 未配置时为 null。
final analysisAgentProvider = FutureProvider<AnalysisAgent?>((ref) async {
  final llm = ref.watch(llmServiceProvider);
  if (llm == null) return null;
  final db = (await ref.watch(appDatabaseProvider.future)).db;
  return AnalysisAgent(
    llm: llm,
    logsDao: WorkoutLogsDao(db),
    memoryDao: AgentMemoryDao(db),
    eventLog: EventLogDao(db),
  );
});

/// Suggestion Agent 装配（架构 5.3）；LLM 未配置时为 null。
final suggestionAgentProvider = FutureProvider<SuggestionAgent?>((ref) async {
  final llm = ref.watch(llmServiceProvider);
  if (llm == null) return null;
  final db = (await ref.watch(appDatabaseProvider.future)).db;
  return SuggestionAgent(
    llm: llm,
    logsDao: WorkoutLogsDao(db),
    memoryDao: AgentMemoryDao(db),
    eventLog: EventLogDao(db),
  );
});
