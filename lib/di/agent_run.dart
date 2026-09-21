import 'package:conatus/conatus.dart';

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