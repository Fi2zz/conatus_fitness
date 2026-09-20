import 'dart:convert';

import 'package:conatus/conatus.dart' hide ToolResult;
import 'package:uuid/uuid.dart';

import '../../../core/tools/tool.dart';
import '../data/agent_memory_dao.dart';
import '../data/event_log_dao.dart';
import '../data/workout_logs_dao.dart';
import '../domain/training_suggestion.dart';
import '../domain/training_suggestion_codec.dart';
import 'analysis_stats.dart';
import 'suggestion_input.dart';
import 'suggestion_prompt.dart';
import 'validate_suggestion_tool.dart';

/// Suggestion Agent（架构 5.3，Multi-Agent 的 MVP 落地）。
///
/// Phase 2 说明：完整编排为 TrainingLoad/Recovery/Preference 三个 Expert
/// （ReAct）+ Synthesizer（Planner）。MVP 以单 AgentLoop 等效收敛：训练史由
/// Agent 自取注入 brief，Expert 权衡收敛进 system prompt；SafetyGuard 终审
/// 不缺位（validate_suggestion 工具内）。
class SuggestionAgent {
  SuggestionAgent({
    required this.llm,
    required this.logsDao,
    required this.memoryDao,
    required this.eventLog,
  });

  final LlmProvider llm;
  final WorkoutLogsDao logsDao;
  final AgentMemoryDao memoryDao;
  final EventLogDao eventLog;

  static const _maxSteps = 6; // 单次 validate 提交即可收口
  static const _maxRetries = 2;
  static const _source = 'suggestion_agent';
  static const _historyDays = 14;

  Future<ToolResult<TrainingSuggestion>> suggest(SuggestionInput input) async {
    final validate = ValidateSuggestionTool(
      recoveryScore: input.recoveryScore,
      painReported: input.painReported,
    );
    final tools = ToolRegistry()..register(validate);

    final prompt = SystemPrompt()
      ..section(PromptSection(name: 'suggestion', text: SuggestionPrompt.system));
    final loop = AgentLoop(
      llm: llm,
      tools: tools,
      session: Session(id: 'suggestion_${const Uuid().v4()}'),
      systemPrompt: prompt,
      reflector: Reflector(
        llm: llm,
        strategy: ReflectionStrategy.onError,
        maxRetries: _maxRetries,
      ),
      maxSteps: _maxSteps,
    );

    try {
      await loop.run(SuggestionPrompt.userBrief(input, await _historySummary()));
    } on LlmException catch (error) {
      return RetryableError('LLM 调用失败：${error.message}');
    }
    final suggestion = validate.latestSuggestion;
    if (suggestion == null) {
      await _log('suggestion_rejected', '最终回复未通过 validate_suggestion 校验');
      return const FatalError('生成的建议未通过校验', suggestion: '请重试，或简化需求后重试');
    }
    await memoryDao.save(
      domain: 'training',
      kind: 'suggestion',
      content: jsonEncode(TrainingSuggestionCodec.toJson(suggestion)),
    );
    return Ok(suggestion);
  }

  Future<String> _historySummary() async {
    final logs = await logsDao.listSince(
      DateTime.now().subtract(const Duration(days: _historyDays)),
    );
    if (logs.isEmpty) return '（近 $_historyDays 天暂无训练记录，请给出保守建议）';
    final sessions = logs.map((log) => log.sessionId).toSet().length;
    return [
      '近 $_historyDays 天共 $sessions 次训练：',
      for (final entry in byExercise(logs)) renderStats(entry.key, entry.value),
    ].join('\n');
  }

  Future<void> _log(String kind, String reason) => eventLog.record(
        const Uuid().v4(),
        _source,
        {'kind': kind, 'reason': reason},
      );
}
