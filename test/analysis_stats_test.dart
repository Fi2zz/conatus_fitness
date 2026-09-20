import 'package:flutter_test/flutter_test.dart';

import 'package:conatus_fitness/features/training/agents/analysis_stats.dart';
import 'package:conatus_fitness/features/training/data/workout_logs_dao.dart';

WorkoutSetLog log(
  String exercise,
  double weight,
  int reps, {
  double? rpe,
  String session = 's1',
}) =>
    WorkoutSetLog(
      exercise: exercise,
      setNumber: 1,
      weight: weight,
      reps: reps,
      sessionId: session,
      performedAt: DateTime(2026),
      rpe: rpe,
    );

void main() {
  test('summarize：容量/峰值/平均 RPE/去重 session 数', () {
    final stats = summarize([
      log('深蹲', 100, 5, rpe: 7, session: 'a'),
      log('深蹲', 110, 5, rpe: 9, session: 'b'),
      log('卧推', 60, 8, session: 'b'),
    ]);
    expect(stats.sets, 3);
    expect(stats.sessions, 2);
    expect(stats.totalVolume, 100 * 5 + 110 * 5 + 60 * 8);
    expect(stats.maxWeight, 110);
    expect(stats.avgRpe, closeTo(8.0, 1e-9));
  });

  test('summarize：无 RPE 记录时 avgRpe 为 null', () {
    expect(summarize([log('深蹲', 100, 5)]).avgRpe, isNull);
  });

  test('overloadRate：后半程相对前半程的容量变化', () {
    final rate = overloadRate([
      log('深蹲', 80, 5),
      log('深蹲', 80, 5),
      log('深蹲', 88, 5),
      log('深蹲', 88, 5),
    ]);
    expect(rate, closeTo(0.1, 1e-9));
  });

  test('overloadRate：数据不足返回 null', () {
    expect(overloadRate([log('深蹲', 80, 5)]), isNull);
  });

  test('byExercise：按容量降序分组', () {
    final entries = byExercise([
      log('卧推', 60, 8),
      log('深蹲', 100, 5),
      log('深蹲', 100, 5),
    ]);
    expect(entries.first.key, '深蹲');
    expect(entries.last.key, '卧推');
  });

  test('renderStats：包含组数与容量文本', () {
    final text = renderStats('整体', summarize([log('深蹲', 100, 5)]));
    expect(text, contains('1 组'));
    expect(text, contains('500kg'));
  });
}
