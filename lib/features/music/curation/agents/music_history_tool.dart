import 'package:conatus/conatus.dart';

import '../data/music_prefs_dao.dart';

/// 用户音乐偏好反馈查询工具（架构 6.1 GetUserMusicHistoryTool）。
class MusicHistoryTool extends Tool {
  MusicHistoryTool(this.prefsDao);

  static const toolName = 'music_history';

  final MusicPrefsDao prefsDao;

  @override
  String get name => toolName;

  @override
  String get description => '读取用户的音乐偏好反馈（跳过/循环/评分及对应训练情境），用于个性化选曲。';

  @override
  List<ParamSpec> get params => const <ParamSpec>[];

  @override
  Future<ToolResult> call(ToolContext context) async {
    final signals = await prefsDao.listSignals();
    if (signals.isEmpty) {
      return ToolResult.success('暂无偏好记录，按通用训练 BPM 曲线策展即可');
    }
    final lines = <String>[
      for (final signal in signals)
        '${signal.signal}｜曲目：${signal.trackId ?? '未知'}｜'
            '情境：${signal.context ?? '无'}',
    ];
    return ToolResult.success('用户音乐偏好反馈：\n${lines.join('\n')}');
  }
}
