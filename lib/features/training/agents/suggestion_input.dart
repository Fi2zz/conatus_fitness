/// Suggestion Agent 输入（MVP）：主观恢复信号由用户提供，训练史由 Agent 自取。
class SuggestionInput {
  const SuggestionInput({required this.recoveryScore, required this.painReported});

  /// 主观恢复评分，0-10（架构 14.3.1：< 2 强制 rest）。
  final int recoveryScore;

  /// 用户是否报告疼痛。
  final bool painReported;
}
