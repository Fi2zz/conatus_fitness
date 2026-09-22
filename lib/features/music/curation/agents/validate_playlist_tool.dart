import 'dart:convert';

import 'package:conatus/conatus.dart';

import '../../../../core/safety/safety_guard.dart';
import '../../domain/music_playlist.dart';
import '../../domain/music_playlist_codec.dart';
import 'playlist_output_schema.dart';
import 'playlist_safety_rules.dart';

/// 歌单提交校验工具：结构校验 + SafetyGuard 终审（架构 14.3.1）。
///
/// 校验失败返回结构化失败（触发 reflectAndRetry 反思重试）；
/// 通过时持有 [MusicPlaylist]，由 CuratorAgent 落库。
class ValidatePlaylistTool extends Tool {
  ValidatePlaylistTool();

  static const toolName = 'validate_playlist';

  MusicPlaylist? latestPlaylist;
  String status = '';

  @override
  String get name => toolName;

  @override
  String get description =>
      '提交训练歌单做结构校验与安全终审（歌单字段结构即本工具参数）。'
      '完成歌单后必须调用；校验通过后，把返回的 JSON 原样作为最终回复输出，'
      '不要附加任何文字。';

  @override
  List<ParamSpec> get params => playlistOutputParams();

  @override
  Future<ToolResult> call(ToolContext context) async {
    final playlist = MusicPlaylistCodec.tryParseMap(context.arguments);
    if (playlist == null) {
      const message =
          '歌单未通过 JSON 结构校验：name/sections/stage/tracks '
          '结构不完整，或 bpm/energy 数值越界';
      return ToolResult.failure(
        message,
        error: const ToolError('playlist_invalid', message),
      );
    }
    final verdict = SafetyGuard<MusicPlaylist>(
      rules: playlistSafetyRules(),
    ).check(playlist);
    switch (verdict) {
      case SafetyBlocked(:final reason):
        return ToolResult.failure(
          '安全校验拦截：$reason。请调整后重新提交',
          error: ToolError('safety_blocked', reason),
        );
      case SafetyRewritten(:final rewritten, :final reason):
        latestPlaylist = rewritten;
        status = 'rewritten';
        return ToolResult.success(
          '校验通过（安全改写：$reason）。最终回复请原样输出：'
          '${jsonEncode(rewritten.toJson())}',
          value: rewritten,
        );
      case SafetyPassed():
        latestPlaylist = playlist;
        status = 'passed';
        return ToolResult.success(
          '校验通过。最终回复请原样输出该 JSON，不要附加文字：'
          '${jsonEncode(playlist.toJson())}',
          value: playlist,
        );
    }
  }
}
