import 'package:conatus/conatus.dart';
import 'package:uuid/uuid.dart';

import '../../../core/agents/agent_outcome.dart';
import '../../../core/logging/app_log.dart';
import '../../../data/event_log_dao.dart';
import '../../../di/agent_run.dart';
import '../data/agent_memory_dao.dart';
import '../data/workout_logs_dao.dart';
import 'analysis_log_tools.dart';
import 'analysis_prompt.dart';
import 'compare_periods_tool.dart';
import 'progress_analysis_tool.dart';
import 'recovery_signal_tool.dart';

/// Analysis Agent（架构 5.2，ReAct 范式落地）。
///
/// 消费框架服务：[LlmProvider] / [ToolRegistry] / [AgentLoop] / [Reflector]
/// 均来自 Conatus。编排链路：
/// Prompt → AgentLoop 工具循环（取数 → 统计 → 对比 → 恢复信号）→
/// 最终文本结论落 agent_memory（domain='training', kind='analysis'）。
/// 输出为文本结论、无负荷处方，故不经 SafetyGuard（14.3.1 仅约束身体负荷输出）。
class AnalysisAgent {
  AnalysisAgent({
    required this.ctx,
    required this.logsDao,
    required this.memoryDao,
    required this.eventLog,
  });

  final Context ctx;
  final WorkoutLogsDao logsDao;
  final AgentMemoryDao memoryDao;
  final EventLogDao eventLog;

  static const _maxSteps = 10; // 工具循环步数上限
  static const _maxRetries = 2;
  static const _source = 'analysis_agent';

  Future<AgentOutcome<String>> analyze() async {
    final tools = ToolRegistry()
      ..register(WorkoutLogQueryTool(logsDao))
      ..register(ProgressAnalysisTool(logsDao))
      ..register(ComparePeriodsTool(logsDao))
      ..register(const RecoverySignalTool());

    final prompt = SystemPrompt()
      ..section(PromptSection(name: 'analysis', text: AnalysisPrompt.system));
    final run = AgentRun.open(
      ctx,
      name: 'analysis',
      tools: tools,
      systemPrompt: prompt,
      session: Session(id: 'analysis_${const Uuid().v4()}'),
      maxSteps: _maxSteps,
      maxRetries: _maxRetries,
    );

    final AgentTurn turn;
    try {
      turn = await run.loop.run(
        AnalysisPrompt.userBrief(await _previousConclusion()),
      );
    } on LlmException catch (error, stackTrace) {
      AppLog.error(_source, 'LLM 调用失败', error, stackTrace);
      return RetryableError('LLM 调用失败：${error.message}');
    } finally {
      run.dispose();
    }
    final reply = turn.reply.trim();
    if (reply.isEmpty) {
      await _log('analysis_empty', '最终回复为空');
      AppLog.error(_source, '未能生成分析结论：模型最终回复为空');
      return const FatalError('未能生成分析结论', suggestion: '请重试，或先录入训练记录');
    }
    await memoryDao.save(domain: 'training', kind: 'analysis', content: reply);
    return Ok(reply);
  }

  Future<String?> _previousConclusion() async {
    final previous = await memoryDao.listLatest(
      domain: 'training',
      kind: 'analysis',
      limit: 1,
    );
    return previous.isEmpty ? null : previous.first;
  }

  Future<void> _log(String kind, String reason) => eventLog.record(
    const Uuid().v4(),
    _source,
    {'kind': kind, 'reason': reason},
  );
}
