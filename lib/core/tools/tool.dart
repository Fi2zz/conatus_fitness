/// 工具返回契约（架构 11.0）：成功 / 可重试 / 不可重试。
sealed class ToolResult<O> {
  const ToolResult();
}

class Ok<O> extends ToolResult<O> {
  const Ok(this.value);

  final O value;
}

/// 网络抖动等瞬时失败，Agent 可自动重试 ≤ 2 次；超时也按此处理。
class RetryableError<O> extends ToolResult<O> {
  const RetryableError(this.message);

  final String message;
}

/// 不可重试，Agent 必须降级或经 TTS/UI 告知用户，不得静默吞掉。
class FatalError<O> extends ToolResult<O> {
  const FatalError(this.message, {this.suggestion});

  final String message;
  final String? suggestion;
}

/// 工具契约（架构 11.0）。名字统一 PascalCase + Tool 后缀。
abstract class ConatusTool<I, O> {
  String get name;

  /// 输入参数 Schema（JSON Schema 形式），供 LLM 与校验共用。
  Map<String, Object?> get inputSchema;

  /// 返回值 Schema。
  Map<String, Object?> get outputSchema;

  /// 超时，默认 5s；超时按 RetryableError 处理。
  Duration get timeout => const Duration(seconds: 5);

  Future<ToolResult<O>> call(I input);
}
