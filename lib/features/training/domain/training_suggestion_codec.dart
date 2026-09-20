import 'dart:convert';

import 'training_suggestion.dart';

/// 训练建议 JSON codec：结构解析 + 枚举校验（架构 5.3 输出结构）。
abstract final class TrainingSuggestionCodec {
  static TrainingSuggestion? tryParse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, Object?>) return null;
    final type = decoded['suggestion_type'];
    final reasoning = decoded['reasoning'];
    if (type is! String || !TrainingSuggestion.types.contains(type)) return null;
    if (reasoning is! String || reasoning.isEmpty) return null;
    return TrainingSuggestion(
      suggestionType: type,
      reasoning: reasoning,
      nextSessionFocus: decoded['next_session_focus']?.toString() ?? '',
      recommendedMusicMood: decoded['recommended_music_mood']?.toString() ?? '',
      safetyFlag: decoded['safety_flag'] == true,
    );
  }

  static Map<String, Object?> toJson(TrainingSuggestion suggestion) =>
      <String, Object?>{
        'suggestion_type': suggestion.suggestionType,
        'reasoning': suggestion.reasoning,
        'next_session_focus': suggestion.nextSessionFocus,
        'recommended_music_mood': suggestion.recommendedMusicMood,
        'safety_flag': suggestion.safetyFlag,
      };
}
