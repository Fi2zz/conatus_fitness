import '../data/workout_logs_dao.dart';

/// 单个时间窗口的容量/强度汇总（分析工具与建议 Agent 共用）。
class VolumeStats {
  const VolumeStats({
    required this.sessions,
    required this.sets,
    required this.totalVolume,
    required this.maxWeight,
    required this.avgRpe,
  });

  final int sessions;
  final int sets;
  final double totalVolume;
  final double maxWeight;
  final double? avgRpe;
}

/// 记录集汇总。
VolumeStats summarize(Iterable<WorkoutSetLog> logs) {
  var volume = 0.0;
  var peak = 0.0;
  var rpeSum = 0.0;
  var rpeCount = 0;
  final sessions = <String>{};
  for (final log in logs) {
    volume += log.volume;
    if (log.weight > peak) peak = log.weight;
    final rpe = log.rpe;
    if (rpe != null) {
      rpeSum += rpe;
      rpeCount++;
    }
    sessions.add(log.sessionId);
  }
  return VolumeStats(
    sessions: sessions.length,
    sets: logs.length,
    totalVolume: volume,
    maxWeight: peak,
    avgRpe: rpeCount == 0 ? null : rpeSum / rpeCount,
  );
}

/// 按动作分组汇总，容量降序。
List<MapEntry<String, VolumeStats>> byExercise(Iterable<WorkoutSetLog> logs) {
  final grouped = <String, List<WorkoutSetLog>>{};
  for (final log in logs) {
    grouped.putIfAbsent(log.exercise, () => []).add(log);
  }
  final entries = [
    for (final entry in grouped.entries) MapEntry(entry.key, summarize(entry.value)),
  ];
  entries.sort((a, b) => b.value.totalVolume.compareTo(a.value.totalVolume));
  return entries;
}

/// 渐进超负荷率：后半程相对前半程的容量变化；数据不足返回 null。
double? overloadRate(List<WorkoutSetLog> chronologicalLogs) {
  if (chronologicalLogs.length < 4) return null;
  final half = chronologicalLogs.length ~/ 2;
  final first = summarize(chronologicalLogs.take(half));
  final second = summarize(chronologicalLogs.skip(half));
  if (first.totalVolume <= 0) return null;
  return (second.totalVolume - first.totalVolume) / first.totalVolume;
}

/// 单行统计文本。
String renderStats(String label, VolumeStats stats) {
  final rpe = stats.avgRpe == null ? '无 RPE' : stats.avgRpe!.toStringAsFixed(1);
  return '$label：${stats.sets} 组 / 容量 ${stats.totalVolume.toStringAsFixed(0)}kg'
      ' / 峰值 ${stats.maxWeight.toStringAsFixed(0)}kg / 平均 RPE $rpe';
}
