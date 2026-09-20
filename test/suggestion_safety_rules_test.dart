import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:conatus_fitness/core/safety/safety_guard.dart';
import 'package:conatus_fitness/features/training/agents/suggestion_safety_rules.dart';
import 'package:conatus_fitness/features/training/domain/training_suggestion.dart';
import 'package:conatus_fitness/features/training/domain/training_suggestion_codec.dart';

TrainingSuggestion suggestion(String type, {bool safetyFlag = false}) =>
    TrainingSuggestion(
      suggestionType: type,
      reasoning: '容量趋势向上，恢复尚可',
      nextSessionFocus: '下肢力量',
      recommendedMusicMood: 'high_energy',
      safetyFlag: safetyFlag,
    );

void main() {
  group('LowRecoveryRule（架构 14.3.1 硬规则）', () {
    test('恢复评分 1 且建议加量 → 强制改写为 rest', () {
      final verdict = const LowRecoveryRule(
        recoveryScore: 1,
        painReported: false,
      ).check(suggestion('increase_load'));
      expect(verdict, isA<SafetyRewritten<TrainingSuggestion>>());
      final rewritten =
          (verdict as SafetyRewritten<TrainingSuggestion>).rewritten;
      expect(rewritten.suggestionType, 'rest');
      expect(rewritten.safetyFlag, isTrue);
      expect(rewritten.reasoning, contains('安全改写'));
    });

    test('报告疼痛且建议维持 → 强制改写为 rest', () {
      final verdict = const LowRecoveryRule(
        recoveryScore: 8,
        painReported: true,
      ).check(suggestion('maintain'));
      expect(verdict, isA<SafetyRewritten<TrainingSuggestion>>());
      expect(
        (verdict as SafetyRewritten<TrainingSuggestion>)
            .rewritten
            .suggestionType,
        'rest',
      );
    });

    test('评分 2 及以上且无疼痛 → 放行', () {
      expect(
        const LowRecoveryRule(
          recoveryScore: 2,
          painReported: false,
        ).check(suggestion('increase_load')),
        isA<SafetyPassed>(),
      );
    });

    test('已是 rest → 原样放行', () {
      expect(
        const LowRecoveryRule(
          recoveryScore: 1,
          painReported: true,
        ).check(suggestion('rest')),
        isA<SafetyPassed>(),
      );
    });
  });

  group('TrainingSuggestionCodec', () {
    test('合法 JSON → 解析成功', () {
      final parsed = TrainingSuggestionCodec.tryParse(
        '{"suggestion_type":"deload","reasoning":"连续两次 RPE 9.5",'
        '"next_session_focus":"上肢","recommended_music_mood":"calm",'
        '"safety_flag":true}',
      );
      expect(parsed, isNotNull);
      expect(parsed!.suggestionType, 'deload');
      expect(parsed.safetyFlag, isTrue);
    });

    test('非法枚举 / 空 reasoning / 坏 JSON → null', () {
      expect(
        TrainingSuggestionCodec.tryParse('{"suggestion_type":"boost"}'),
        isNull,
      );
      expect(
        TrainingSuggestionCodec.tryParse(
          '{"suggestion_type":"rest","reasoning":""}',
        ),
        isNull,
      );
      expect(TrainingSuggestionCodec.tryParse('not json'), isNull);
    });

    test('toJson 往返一致', () {
      final original = suggestion('maintain', safetyFlag: true);
      final encoded = jsonEncode(TrainingSuggestionCodec.toJson(original));
      final parsed = TrainingSuggestionCodec.tryParse(encoded);
      expect(parsed, isNotNull);
      expect(parsed!.suggestionType, 'maintain');
      expect(parsed.safetyFlag, isTrue);
      expect(parsed.reasoning, original.reasoning);
    });
  });
}
