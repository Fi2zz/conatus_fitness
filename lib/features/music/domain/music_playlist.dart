/// MusicCurator Agent 输出契约（架构 6.1）。JSON 字段保持 snake_case。
class PlaylistTrack {
  const PlaylistTrack({
    required this.title,
    required this.bpm,
    required this.energy,
    this.artist,
    this.reason,
  });

  final String title;
  final String? artist;
  final int bpm;
  final double energy;
  final String? reason;

  Map<String, Object?> toJson() => <String, Object?>{
    'title': title,
    'artist': artist,
    'bpm': bpm,
    'energy': energy,
    'reason': reason,
  };
}

class PlaylistSection {
  const PlaylistSection({
    required this.stage,
    required this.mood,
    required this.tracks,
  });

  final String stage;
  final String mood;
  final List<PlaylistTrack> tracks;

  Map<String, Object?> toJson() => <String, Object?>{
    'stage': stage,
    'mood': mood,
    'tracks': [for (final track in tracks) track.toJson()],
  };
}

class MusicPlaylist {
  const MusicPlaylist({
    required this.name,
    required this.notes,
    required this.sections,
  });

  final String name;
  final String notes;
  final List<PlaylistSection> sections;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'notes': notes,
    'sections': [for (final section in sections) section.toJson()],
  };
}

/// 训练四阶段（架构 6.1：热身 → 主项 → 力竭 → 拉伸）。
const playlistStages = <String>['warmup', 'main', 'fatigue', 'stretch'];

/// 阶段中文标签（校验消息与 UI 共用）。
const stageLabels = <String, String>{
  'warmup': '热身',
  'main': '主项',
  'fatigue': '力竭',
  'stretch': '拉伸',
};
