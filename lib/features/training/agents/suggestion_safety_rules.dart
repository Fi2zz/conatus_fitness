import '../../../core/safety/safety_guard.dart';
import '../domain/training_suggestion.dart';

/// 恢复不足 → 强制 rest（架构 14.3.1 硬规则）。
///
/// `recovery_score < 2` 或用户报告疼痛时，无论 LLM 给出什么类型，
/// 建议一律改写为 rest；已是 rest 则原样放行。
class LowRecoveryRule extends SafetyRule<TrainingSuggestion> {
  const LowRecoveryRule({required this.recoveryScore, required this.painReported});

  final int recoveryScore;
  final bool painReported;

  @override
  String get name => 'low_recovery_forced_rest';

  @override
  SafetyVerdict check(TrainingSuggestion input) {
    final lowRecovery = recoveryScore < 2;
    if ((!lowRecovery && !painReported) || input.suggestionType == 'rest') {
      return const SafetyPassed();
    }
    final cause = painReported ? '用户报告疼痛' : '恢复评分仅 $recoveryScore 分';
    final rewritten = TrainingSuggestion(
      suggestionType: 'rest',
      reasoning: '${input.reasoning}（安全改写：$cause，本次建议强制休息）',
      nextSessionFocus: input.nextSessionFocus,
      recommendedMusicMood: 'calm',
      safetyFlag: true,
    );
    return SafetyRewritten(rewritten, '恢复不足（$cause），已强制改为 rest');
  }
}

/// Suggestion 输出的硬规则组合（架构 14.3.1）。
List<SafetyRule<TrainingSuggestion>> suggestionSafetyRules({
  required int recoveryScore,
  required bool painReported,
}) =>
    [
      LowRecoveryRule(recoveryScore: recoveryScore, painReported: painReported),
    ];
