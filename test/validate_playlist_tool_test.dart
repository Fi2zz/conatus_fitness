import 'package:flutter_test/flutter_test.dart';

import 'package:conatus/conatus.dart' show ToolCall, ToolContext, ToolResult;
import 'package:conatus_fitness/features/music/curation/agents/validate_playlist_tool.dart';

const validPlaylist = '''
{
  "name": "下肢力量 · 推进曲线",
  "notes": "慢起快落",
  "sections": [
    {"stage": "warmup", "mood": "渐进唤醒", "tracks": [
      {"title": "Eye of the Tiger", "artist": "Survivor", "bpm": 109, "energy": 0.6},
      {"title": "Stronger", "artist": "Kanye West", "bpm": 104, "energy": 0.7}
    ]},
    {"stage": "main", "mood": "稳定节奏", "tracks": [
      {"title": "Till I Collapse", "artist": "Eminem", "bpm": 148, "energy": 0.9},
      {"title": "Power", "artist": "Kanye West", "bpm": 154, "energy": 0.9}
    ]},
    {"stage": "fatigue", "mood": "峰值激励", "tracks": [
      {"title": "Believer", "artist": "Imagine Dragons", "bpm": 150, "energy": 0.95},
      {"title": "Can't Hold Us", "artist": "Macklemore", "bpm": 165, "energy": 0.95}
    ]},
    {"stage": "stretch", "mood": "降速放松", "tracks": [
      {"title": "Weightless", "artist": "Marconi Union", "bpm": 60, "energy": 0.2},
      {"title": "Horizon Variations", "artist": "Max Richter", "bpm": 75, "energy": 0.3}
    ]}
  ]
}
''';

Future<ToolResult> submit(ValidatePlaylistTool tool, String json) => tool.call(
  ToolContext(
    ToolCall(
      name: ValidatePlaylistTool.toolName,
      arguments: {'playlist_json': json},
    ),
  ),
);

void main() {
  test('合法歌单 → 通过并持有 latestPlaylist', () async {
    final tool = ValidatePlaylistTool();
    await submit(tool, validPlaylist);
    expect(tool.latestPlaylist, isNotNull);
    expect(tool.status, 'passed');
    expect(tool.latestPlaylist!.name, '下肢力量 · 推进曲线');
    expect(tool.latestPlaylist!.sections.length, 4);
  });

  test('结构非法 → playlist_invalid 失败', () async {
    final tool = ValidatePlaylistTool();
    await submit(tool, '{"name": "歌单", "sections": []}');
    expect(tool.latestPlaylist, isNull);
  });

  test('BPM 超阶段区间 → 拦截', () async {
    final tool = ValidatePlaylistTool();
    final broken = validPlaylist.replaceAll('"bpm": 148', '"bpm": 185');
    final result = await submit(tool, broken);
    expect(result.isError, isTrue);
    expect(result.error?.code, 'safety_blocked');
    expect(result.content, contains('主项'));
    expect(tool.latestPlaylist, isNull);
  });

  test('阶段曲线不完整 → 拦截', () async {
    final tool = ValidatePlaylistTool();
    final broken = validPlaylist.replaceFirst(
      '"stage": "stretch"',
      '"stage": "warmup"',
    );
    final result = await submit(tool, broken);
    expect(result.isError, isTrue);
    expect(result.error?.code, 'safety_blocked');
    expect(tool.latestPlaylist, isNull);
  });

  test('非 JSON 文本 → 失败', () async {
    final tool = ValidatePlaylistTool();
    final result = await submit(tool, '这个歌单没问题的');
    expect(result.isError, isTrue);
    expect(result.error?.code, 'playlist_invalid');
  });
}
