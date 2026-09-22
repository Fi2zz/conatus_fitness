import 'dart:convert';

import 'music_playlist.dart';

/// LLM 输出 → [MusicPlaylist] 的解析与结构校验（架构 6.1）。
///
/// 校验失败返回 null，由 Curator Agent 触发反思重试（≤ 2 次）。
abstract final class MusicPlaylistCodec {
  static MusicPlaylist? tryParse(String raw) {
    final root = _decode(raw);
    if (root == null) return null;
    return tryParseMap(root);
  }

  /// 解析已结构化的歌单对象（function calling 的工具参数即此形态）。
  static MusicPlaylist? tryParseMap(Map<String, Object?> root) {
    final name = root['name']?.toString() ?? '';
    if (name.isEmpty) return null;
    final sections = _parseSections(root['sections']);
    if (sections == null) return null;
    return MusicPlaylist(
      name: name,
      notes: root['notes']?.toString() ?? '',
      sections: sections,
    );
  }

  static Map<String, dynamic>? _decode(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text
          .replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '')
          .replaceAll('```', '')
          .trim();
    }
    try {
      final value = jsonDecode(text);
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }

  static List<PlaylistSection>? _parseSections(Object? node) {
    if (node is! List || node.isEmpty) return null;
    final sections = <PlaylistSection>[];
    for (final sectionNode in node) {
      if (sectionNode is! Map<String, dynamic>) return null;
      final section = _parseSection(sectionNode);
      if (section == null) return null;
      sections.add(section);
    }
    return sections;
  }

  static PlaylistSection? _parseSection(Map<String, dynamic> node) {
    final stage = node['stage']?.toString() ?? '';
    final tracks = _parseTracks(node['tracks']);
    if (!playlistStages.contains(stage) || tracks == null) return null;
    return PlaylistSection(
      stage: stage,
      mood: node['mood']?.toString() ?? '',
      tracks: tracks,
    );
  }

  static List<PlaylistTrack>? _parseTracks(Object? node) {
    if (node is! List || node.isEmpty) return null;
    final tracks = <PlaylistTrack>[];
    for (final trackNode in node) {
      if (trackNode is! Map<String, dynamic>) return null;
      final track = _parseTrack(trackNode);
      if (track == null) return null;
      tracks.add(track);
    }
    return tracks;
  }

  static PlaylistTrack? _parseTrack(Map<String, dynamic> node) {
    final title = node['title']?.toString() ?? '';
    final bpm = node['bpm'];
    final energy = node['energy'];
    if (title.isEmpty || bpm is! int || bpm < 60 || bpm > 190) return null;
    if (energy is! num || energy < 0 || energy > 1) return null;
    return PlaylistTrack(
      title: title,
      artist: node['artist']?.toString(),
      bpm: bpm,
      energy: energy.toDouble(),
      reason: node['reason']?.toString(),
    );
  }
}
