import 'package:conatus/conatus.dart';
import 'package:uuid/uuid.dart';

import '../../../core/agents/agent_outcome.dart';
import '../../../core/logging/app_log.dart';
import '../../../data/event_log_dao.dart';
import '../../../di/agent_run.dart';
import '../data/plans_dao.dart';
import 'injury_check_tool.dart';
import 'planner_input.dart';
import 'planner_prompt.dart';
import 'validate_plan_tool.dart';

/// Planner Agent（架构 5.1，ReAct 范式落地）。
///
/// 消费框架服务：[LlmProvider] / [ToolRegistry] / [AgentLoop] / [Reflector]
/// 均来自 Conatus。编排链路：
/// Prompt → AgentLoop 工具循环（injury_check 伤病自检 → validate_plan
/// 结构校验 + SafetyGuard 终审，失败经 reflectAndRetry 反思重试）→ 落库。
class PlannerAgent {
  PlannerAgent({
    required this.ctx,
    required this.plansDao,
    required this.eventLog,
  });

  final Context ctx;
  final PlansDao plansDao;
  final EventLogDao eventLog;

  static const _maxSteps = 8; // 工具循环步数上限
  static const _maxRetries = 2; // 校验失败反思重试上限（架构 5.1：≤ 2）
  static const _source = 'planner_agent';

  Future<AgentOutcome<StoredPlan>> generate(PlannerInput input) async {
    final tools = ToolRegistry();
    final validate = ValidatePlanTool(input.injuries);
    tools.register(InjuryCheckTool(input.injuries));
    tools.register(validate);

    final prompt = SystemPrompt()
      ..section(PromptSection(name: 'planner', text: PlannerPrompt.system));
    final run = AgentRun.open(
      ctx,
      name: 'planner',
      tools: tools,
      systemPrompt: prompt,
      session: Session(id: 'planner_${const Uuid().v4()}'),
      maxSteps: _maxSteps,
      maxRetries: _maxRetries,
    );

    try {
      await run.loop.run(PlannerPrompt.userBrief(input));
    } on LlmException catch (error, stackTrace) {
      AppLog.error(_source, 'LLM 调用失败', error, stackTrace);
      return RetryableError('LLM 调用失败：${error.message}');
    } finally {
      run.dispose();
    }
    final plan = validate.latestPlan;
    if (plan == null) {
      await _log('plan_rejected', '最终回复未通过 validate_plan 校验');
      AppLog.error(_source, '生成的计划未通过校验：模型未提交合格的 validate_plan');
      return const FatalError('生成的计划未通过校验', suggestion: '请重试，或简化需求后重试');
    }
    final stored = await plansDao.save(
      plan,
      source: _source,
      safetyStatus: validate.status,
    );
    return Ok(stored);
  }

  Future<void> _log(String kind, String reason) => eventLog.record(
    const Uuid().v4(),
    _source,
    {'kind': kind, 'reason': reason},
  );
}
