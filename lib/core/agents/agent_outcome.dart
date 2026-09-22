/// 一次 Agent 运行收敛出的结局：Agent → UI 的唯一出口。
///
/// 工具层的契约在框架侧（`Tool` / `ToolResult` / `ToolError`），工具只对模型
/// 负责；本类型对用户负责，UI 据此区分「可原样重试」与「需换策略/告知用户」。
sealed class AgentOutcome<O> {
  const AgentOutcome();
}

/// 成功，携带业务产物（计划 / 风险报告 / 建议 / 歌单 / 文本结论）。
class Ok<O> extends AgentOutcome<O> {
  const Ok(this.value);

  final O value;
}

/// 瞬时失败（LLM 调用失败、网络抖动等），可原样重试。
class RetryableError<O> extends AgentOutcome<O> {
  const RetryableError(this.message);

  final String message;
}

/// 不可重试，需告知用户并给出下一步建议。
class FatalError<O> extends AgentOutcome<O> {
  const FatalError(this.message, {this.suggestion});

  final String message;
  final String? suggestion;
}
