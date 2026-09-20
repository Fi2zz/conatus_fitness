import 'package:flutter_test/flutter_test.dart';

import 'package:conatus_fitness/features/training/data/workout_logs_dao.dart';
import 'package:conatus_fitness/features/training/data/workout_session.dart';

WorkoutSetLog log(String session, DateTime at, double weight, int reps) =>
    WorkoutSetLog(
      exercise: '深蹲',
      setNumber: 1,
      weight: weight,
      reps: reps,
      sessionId: session,
      performedAt: at,
    );

void main() {
  test('groupBySession：按课分组且最新在前', () {
    final sessions = groupBySession([
      log('a', DateTime(2026, 1, 1), 100, 5),
      log('b', DateTime(2026, 1, 8), 105, 5),
      log('a', DateTime(2026, 1, 1), 102, 5),
    ]);
    expect(sessions.length, 2);
    expect(sessions.first.sessionId, 'b');
    expect(sessions.last.setCount, 2);
  });

  test('WorkoutSession：组数与总容量', () {
    final session = groupBySession([
      log('a', DateTime(2026), 100, 5),
      log('a', DateTime(2026), 110, 5),
    ]).single;
    expect(session.setCount, 2);
    expect(session.totalVolume, 100 * 5 + 110 * 5);
    expect(session.performedAt, DateTime(2026));
  });

  test('空记录 → 空列表', () {
    expect(groupBySession(const []), isEmpty);
  });
}
