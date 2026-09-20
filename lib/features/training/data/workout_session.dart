import 'workout_logs_dao.dart';

/// 一次训练课的分组视图（历史列表展示用）。
class WorkoutSession {
  const WorkoutSession({
    required this.sessionId,
    required this.performedAt,
    required this.sets,
  });

  final String sessionId;
  final DateTime performedAt;
  final List<WorkoutSetLog> sets;

  int get setCount => sets.length;

  double get totalVolume => sets.fold(0, (sum, log) => sum + log.volume);
}

/// 按训练课分组，日期降序（最新在前）。
List<WorkoutSession> groupBySession(List<WorkoutSetLog> logs) {
  final grouped = <String, List<WorkoutSetLog>>{};
  for (final log in logs) {
    grouped.putIfAbsent(log.sessionId, () => []).add(log);
  }
  final sessions = [
    for (final entry in grouped.entries)
      WorkoutSession(
        sessionId: entry.key,
        performedAt: _earliest(entry.value),
        sets: entry.value,
      ),
  ];
  sessions.sort((a, b) => b.performedAt.compareTo(a.performedAt));
  return sessions;
}

DateTime _earliest(List<WorkoutSetLog> sets) =>
    sets.map((log) => log.performedAt).reduce(
          (a, b) => a.isBefore(b) ? a : b,
        );
