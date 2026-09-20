import 'package:conatus/conatus.dart';

import '../data/workout_logs_dao.dart';
import 'analysis_stats.dart';

/// 进度分析工具（架构 5.2）：容量、强度、渐进超负荷率。
class ProgressAnalysisTool extends Tool {
  ProgressAnalysisTool(this.dao);

  static const toolName = 'progress_analysis';

  final WorkoutLogsDao dao;

  @override
  String get name => toolName;

  @override
  String get description => '计算指定时间窗口的整体与分动作训练容量、'
      '峰值重量、平均 RPE 与渐进超负荷率。';

  @override
  List<ParamSpec> get params => <ParamSpec>[
        ParamSpec.integer('days', description: '回看天数，默认 30'),
      ];

  @override
  Future<ToolResult> call(ToolContext context) async {
    final days = context.integer('days') ?? 30;
    final logs = await dao.listSince(DateTime.now().subtract(Duration(days: days)));
    if (logs.isEmpty) {
      return ToolResult.success('最近 $days 天无训练记录，无法分析');
    }
    final rate = overloadRate(logs);
    final rateText = rate == null ? '数据不足，无法计算' : '${(rate * 100).toStringAsFixed(1)}%';
    final lines = [
      '最近 $days 天统计：',
      renderStats('整体', summarize(logs)),
      '渐进超负荷率（后半程 vs 前半程）：$rateText',
      for (final entry in byExercise(logs)) renderStats(entry.key, entry.value),
    ];
    return ToolResult.success(lines.join('\n'));
  }
}
