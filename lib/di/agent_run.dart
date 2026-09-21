import 'package:conatus/conatus.dart';

/// 工具结果落终端时的正文截断长度（计划 / 歌单 JSON 很长，全量会淹没终端）。
const int _contentLimit = 400;

/// 单次 Agent 运行的装配作用域。
///
/// 「每次运行才产生」的服务（tools / systemPrompt / reflection）注册在派生的
/// 子上下文里，AgentLoop 与 LLM 装饰交由框架 [provideAgentLoop] 装配；运行结束
/// 后 [dispose] 回收子上下文，本次服务不残留到父上下文。
class AgentRun {
  AgentRun._(this._scope, this.loop);

  final Context _scope;

  /// 本次运行的工具循环。
  final AgentLoop loop;

  /// 基于 [ctx]（须已提供 `'llm'`）装配一次运行。
  ///
  /// [name] 用于子上下文命名，便于调试定位；[maxRetries] 为反思重试上限。
  static AgentRun open(
    Context ctx, {
    required String name,
    required ToolRegistry tools,
    required SystemPrompt systemPrompt,
    required Session session,
    required int maxSteps,
    int maxRetries = 2,
  }) {
    final Context scope = ctx.plugin('$name-run', (child) {
      provideTools(child, tools: tools);
      provideSystemPrompt(child, prompt: systemPrompt);
      provideReflection(child, maxRetries: maxRetries);
      // 工具结局落终端：失败带正文（如 validate 的拦截理由），成功只记一行。
      // 这些正文此前只回填给模型，模型不再提及就彻底查不到。
      child.effect(
        () => tools.onResult(
          (ToolCall call, ToolResult result) =>
              _reportTool(child, name, call, result),
        ),
      );
    });
    final AgentLoop loop = provideAgentLoop(
      scope,
      session: session,
      maxSteps: maxSteps,
    );
    return AgentRun._(scope, loop);
  }

  /// 释放本次运行注册的服务。
  void dispose() => _scope.dispose();
}

/// 把一次工具结局投到遥测（终端出口在根上下文注册，见 `agentContextProvider`）。
///
/// 未注册遥测时静默返回，因此单元测试里直连工具不会产生终端噪声。
void _reportTool(Context scope, String run, ToolCall call, ToolResult result) {
  final Telemetry? telemetry = scope.get<Telemetry>('telemetry');
  if (telemetry == null) return;
  final String content = result.content;
  telemetry.emit(
    TelemetryEvent(
      'tool.result',
      data: <String, Object?>{
        'run': run,
        'tool': call.name,
        'isError': result.isError,
        'content': content.length <= _contentLimit
            ? content
            : '${content.substring(0, _contentLimit)}…',
      },
    ),
  );
}
