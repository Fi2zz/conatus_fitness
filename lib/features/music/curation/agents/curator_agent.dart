import 'package:conatus/conatus.dart' hide ToolResult;
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_log.dart';
import '../../../../core/tools/tool.dart';
import '../../../../data/event_log_dao.dart';
import '../../../../di/agent_run.dart';
import '../../domain/music_playlist.dart';
import '../data/music_prefs_dao.dart';
import '../data/playlists_dao.dart';
import 'curator_input.dart';
import 'curator_prompt.dart';
import 'music_history_tool.dart';
import 'validate_playlist_tool.dart';

/// MusicCurator Agent（架构 6.1，Planner 范式落地）。
///
/// 消费框架服务：[LlmProvider] / [ToolRegistry] / [AgentLoop] / [Reflector]
/// 均来自 Conatus。编排链路：
/// Prompt → AgentLoop 工具循环（music_history 偏好查询 → validate_playlist
/// 结构校验 + SafetyGuard 终审，失败经 reflectAndRetry 反思重试）→ 落库。
class CuratorAgent {
  CuratorAgent({
    required this.ctx,
    required this.playlistsDao,
    required this.prefsDao,
    required this.eventLog,
  });

  final Context ctx;
  final PlaylistsDao playlistsDao;
  final MusicPrefsDao prefsDao;
  final EventLogDao eventLog;

  static const _maxSteps = 6; // 工具循环步数上限
  static const _maxRetries = 2; // 校验失败反思重试上限
  static const _source = 'music_curator_agent';

  Future<ToolResult<StoredPlaylist>> generate(CuratorInput input) async {
    final tools = ToolRegistry();
    final validate = ValidatePlaylistTool();
    tools.register(MusicHistoryTool(prefsDao));
    tools.register(validate);

    final prompt = SystemPrompt()
      ..section(
        PromptSection(name: 'music_curator', text: CuratorPrompt.system),
      );
    final run = AgentRun.open(
      ctx,
      name: 'curator',
      tools: tools,
      systemPrompt: prompt,
      session: Session(id: 'curator_${const Uuid().v4()}'),
      maxSteps: _maxSteps,
      maxRetries: _maxRetries,
    );

    try {
      await run.loop.run(CuratorPrompt.userBrief(input));
    } on LlmException catch (error, stackTrace) {
      AppLog.error(_source, 'LLM 调用失败', error, stackTrace);
      return RetryableError('LLM 调用失败：${error.message}');
    } finally {
      run.dispose();
    }
    final playlist = validate.latestPlaylist;
    if (playlist == null) {
      await _log('playlist_rejected', '最终回复未通过 validate_playlist 校验');
      AppLog.error(_source, '歌单未通过校验：模型未提交合格的 validate_playlist');
      return const FatalError('生成的歌单未通过校验', suggestion: '请重试，或简化氛围诉求后重试');
    }
    await _log('playlist_generated', '终审结论：${validate.status}');
    AppLog.info(_source, describePlaylist(playlist));
    final stored = await playlistsDao.save(playlist);
    return Ok(stored);
  }

  Future<void> _log(String kind, String reason) => eventLog.record(
    const Uuid().v4(),
    _source,
    {'kind': kind, 'reason': reason},
  );
}

/// 歌单产出摘要：终端逐首核对选曲（阶段 BPM 标题 / 艺人）。
String describePlaylist(MusicPlaylist playlist) {
  final lines = <String>[
    '歌单「${playlist.name}」共 ${playlist.allTracks.length} 首',
  ];
  for (final section in playlist.sections) {
    for (final track in section.tracks) {
      final artist = track.artist ?? '';
      lines.add('  ${section.stage} ${track.bpm} | ${track.title} / $artist');
    }
  }
  return lines.join('\n');
}
