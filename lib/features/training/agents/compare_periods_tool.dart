import 'package:conatus/conatus.dart';

import '../data/workout_logs_dao.dart';
import 'analysis_stats.dart';

/// 时段对比工具（架构 5.2）：对比最近窗口与上一个等长窗口。
class ComparePeriodsTool extends Tool {
  ComparePeriodsTool(this.dao);

  static const toolName = 'compare_periods';

  final WorkoutLogsDao dao;

  @override
  String get name => toolName;

  @override
  String get description => '对比最近一个窗口与上一个等长窗口的训练指标，'
      '输出整体与分动作的容量变化百分比。';

  @override
  List<ParamSpec> get params => <ParamSpec>[
        ParamSpec.integer('days', description: '窗口天数，默认 14（最近 14 天 vs 之前 14 天）'),
      ];

  @override
  Future<ToolResult> call(ToolContext context) async {
    final days = context.integer('days') ?? 14;
    final now = DateTime.now();
    final logs = await dao.listSince(now.subtract(Duration(days: days * 2)));
    final current = summarize(_window(logs, now.subtract(Duration(days: days)), now));
    final previous =
        summarize(_window(logs, now.subtract(Duration(days: days * 2)), now.subtract(Duration(days: days))));
    if (current.sets == 0 || previous.sets == 0) {
      return ToolResult.success(
        '对比数据不足：当前窗口 ${current.sets} 组 / 上一窗口 ${previous.sets} 组',
      );
    }
    final lines = [
      '窗口对比（各 $days 天）：',
      renderStats('当前窗口', current),
      renderStats('上一窗口', previous),
      '整体容量变化：${_delta(previous.totalVolume, current.totalVolume)}',
    ];
    return ToolResult.success(lines.join('\n'));
  }

  static List<WorkoutSetLog> _window(List<WorkoutSetLog> logs, DateTime from, DateTime to) {
    return [
      for (final log in logs)
        if (!log.performedAt.isBefore(from) && log.performedAt.isBefore(to)) log,
    ];
  }

  static String _delta(double base, double value) {
    if (base <= 0) return '无法计算（基期为 0）';
    final percent = (value - base) / base * 100;
    return '${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(1)}%';
  }
}
