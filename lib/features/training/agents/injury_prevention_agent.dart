import 'dart:convert';

import 'package:conatus/conatus.dart' hide ToolResult;
import 'package:uuid/uuid.dart';

import '../../../core/tools/tool.dart';
import '../../../data/event_log_dao.dart';
import '../data/agent_memory_dao.dart';
import '../data/profile_dao.dart';
import '../data/workout_logs_dao.dart';
import '../domain/injury_risk_report.dart';
import '../domain/injury_risk_report_codec.dart';
import 'analysis_log_tools.dart';
import 'injury_check_tool.dart';
import 'injury_prevention_prompt.dart';
import 'injury_profile_tool.dart';
import 'validate_risk_report_tool.dart';

/// Injury Prevention Agent（ReAct 范式落地）。
///
/// 消费框架服务：[LlmProvider] / [ToolRegistry] / [AgentLoop] / [Reflector]
/// 均来自 Conatus。编排链路：
/// Prompt → AgentLoop 工具循环（读取伤病史 → 取训练负荷 → 冲突自检 →
/// validate_risk_report 结构校验 + SafetyGuard 终审）→
/// 报告落 agent_memory（domain='training', kind='injury_prevention'）。
class InjuryPreventionAgent {
  InjuryPreventionAgent({
    required this.llm,
    required this.logsDao,
    required this.profileDao,
    required this.memoryDao,
    required this.eventLog,
  });

  final LlmProvider llm;
  final WorkoutLogsDao logsDao;
  final ProfileDao profileDao;
  final AgentMemoryDao memoryDao;
  final EventLogDao eventLog;

  static const _maxSteps = 10;
  static const _maxRetries = 2;
  static const _source = 'injury_prevention_agent';

  Future<ToolResult<InjuryRiskReport>> evaluate() async {
    final injuries = (await profileDao.load())?.injuries ?? '';
    final validate = ValidateRiskReportTool(injuries);
    final tools = ToolRegistry()
      ..register(InjuryProfileTool(profileDao))
      ..register(WorkoutLogQueryTool(logsDao))
      ..register(InjuryCheckTool(injuries))
      ..register(validate);

    final prompt = SystemPrompt()
      ..section(
        PromptSection(
          name: 'injury_prevention',
          text: InjuryPreventionPrompt.system,
        ),
      );
    final loop = AgentLoop(
      llm: llm,
      tools: tools,
      session: Session(id: 'injury_prevention_${const Uuid().v4()}'),
      systemPrompt: prompt,
      reflector: Reflector(
        llm: llm,
        strategy: ReflectionStrategy.onError,
        maxRetries: _maxRetries,
      ),
      maxSteps: _maxSteps,
    );

    try {
      await loop.run(InjuryPreventionPrompt.userBrief);
    } on LlmException catch (error) {
      return RetryableError('LLM 调用失败：${error.message}');
    }
    final report = validate.latestReport;
    if (report == null) {
      await _log('report_rejected', '最终回复未通过 validate_risk_report 校验');
      return const FatalError('生成的风险报告未通过校验', suggestion: '请重试，或简化需求后重试');
    }
    await memoryDao.save(
      domain: 'training',
      kind: 'injury_prevention',
      content: jsonEncode(InjuryRiskReportCodec.toJson(report)),
    );
    return Ok(report);
  }

  Future<void> _log(String kind, String reason) => eventLog.record(
    const Uuid().v4(),
    _source,
    {'kind': kind, 'reason': reason},
  );
}
