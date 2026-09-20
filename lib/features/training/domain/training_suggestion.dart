/// Suggestion Agent 输出（架构 5.3）。
class TrainingSuggestion {
  const TrainingSuggestion({
    required this.suggestionType,
    required this.reasoning,
    required this.nextSessionFocus,
    required this.recommendedMusicMood,
    required this.safetyFlag,
  });

  static const types = <String>['increase_load', 'maintain', 'deload', 'rest'];

  final String suggestionType;
  final String reasoning;
  final String nextSessionFocus;
  final String recommendedMusicMood;
  final bool safetyFlag;
}
