import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:conatus_fitness/features/training/domain/training_plan_codec.dart';

void main() {
  const valid = '''
{
  "weeks": [
    {
      "week_number": 1,
      "sessions": [
        {
          "day": "Monday",
          "focus": "下肢力量",
          "exercises": [
            {
              "name": "深蹲",
              "sets": 5,
              "reps": "5",
              "rest_seconds": 180,
              "target_rpe": 8,
              "safety_note": null
            }
          ]
        }
      ]
    }
  ],
  "safety_notes": "注意热身"
}
''';

  test('解析合法 JSON', () {
    final plan = TrainingPlanCodec.tryParse(valid);
    expect(plan, isNotNull);
    expect(plan!.weeks.length, 1);
    expect(plan.weeks.first.weekNumber, 1);
    expect(plan.safetyNotes, '注意热身');
    final exercise = plan.weeks.first.sessions.first.exercises.first;
    expect(exercise.name, '深蹲');
    expect(exercise.sets, 5);
    expect(exercise.reps, '5');
    expect(exercise.restSeconds, 180);
    expect(exercise.targetRpe, 8);
    expect(exercise.safetyNote, isNull);
  });

  test('剥离代码块围栏', () {
    final plan = TrainingPlanCodec.tryParse('```json\n$valid\n```');
    expect(plan, isNotNull);
    expect(plan!.weeks.first.sessions.first.exercises.first.name, '深蹲');
  });

  test('reps 数字自动转为字符串', () {
    final plan = TrainingPlanCodec.tryParse(
      valid.replaceAll('"reps": "5"', '"reps": 8'),
    );
    expect(plan!.weeks.first.sessions.first.exercises.first.reps, '8');
  });

  test('缺失 weeks 返回 null', () {
    expect(TrainingPlanCodec.tryParse('{"safety_notes": ""}'), isNull);
  });

  test('空 weeks 返回 null', () {
    expect(TrainingPlanCodec.tryParse('{"weeks": []}'), isNull);
  });

  test('非法 sets 返回 null', () {
    final broken = valid.replaceAll('"sets": 5', '"sets": 0');
    expect(TrainingPlanCodec.tryParse(broken), isNull);
  });

  test('RPE 越界返回 null', () {
    final broken = valid.replaceAll('"target_rpe": 8', '"target_rpe": 11');
    expect(TrainingPlanCodec.tryParse(broken), isNull);
  });

  test('非 JSON 文本返回 null', () {
    expect(TrainingPlanCodec.tryParse('抱歉，我无法生成计划'), isNull);
  });

  test('toJson 往返一致', () {
    final plan = TrainingPlanCodec.tryParse(valid)!;
    final restored = TrainingPlanCodec.tryParse(jsonEncode(plan.toJson()));
    expect(restored, isNotNull);
    expect(restored!.weeks.length, plan.weeks.length);
    expect(restored.safetyNotes, plan.safetyNotes);
  });
}
