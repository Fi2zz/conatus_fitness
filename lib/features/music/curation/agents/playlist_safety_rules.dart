import '../../../../core/safety/safety_guard.dart';
import '../../domain/music_playlist.dart';

/// 各阶段 BPM 区间（架构 6.1 曲线，SafetyGuard 与 Prompt 同一口径）。
const stageBpmRanges = <String, (int, int)>{
  'warmup': (90, 130),
  'main': (120, 170),
  'fatigue': (130, 180),
  'stretch': (60, 110),
};

/// 每阶段曲目数上下限。
const minTracksPerStage = 2;
const maxTracksPerStage = 6;

/// 阶段覆盖与顺序：四阶段按 热身→主项→力竭→拉伸 各出现一次（架构 6.1）。
class StageCurveRule extends SafetyRule<MusicPlaylist> {
  const StageCurveRule();

  @override
  String get name => 'stage_curve_required';

  @override
  SafetyVerdict check(MusicPlaylist playlist) {
    final stages = [for (final section in playlist.sections) section.stage];
    final curve = playlistStages.map((stage) => stageLabels[stage]).join('→');
    var matches = stages.length == playlistStages.length;
    for (var i = 0; matches && i < stages.length; i++) {
      matches = stages[i] == playlistStages[i];
    }
    if (!matches) {
      return SafetyBlocked('sections 必须按 $curve 顺序各覆盖一次');
    }
    return const SafetyPassed();
  }
}

/// 曲目 BPM 贴合所在阶段区间（架构 6.1 BPM 曲线）。
class StageBpmRule extends SafetyRule<MusicPlaylist> {
  const StageBpmRule();

  @override
  String get name => 'stage_bpm_curve';

  @override
  SafetyVerdict check(MusicPlaylist playlist) {
    for (final section in playlist.sections) {
      final range = stageBpmRanges[section.stage]!;
      for (final track in section.tracks) {
        if (track.bpm < range.$1 || track.bpm > range.$2) {
          final label = stageLabels[section.stage] ?? section.stage;
          return SafetyBlocked(
            '「${track.title}」BPM ${track.bpm} 超出 $label 区间 '
            '${range.$1}-${range.$2}',
          );
        }
      }
    }
    return const SafetyPassed();
  }
}

/// 每阶段曲目数限制：曲线完整且不冗长。
class TrackCountRule extends SafetyRule<MusicPlaylist> {
  const TrackCountRule();

  @override
  String get name => 'track_count_limit';

  @override
  SafetyVerdict check(MusicPlaylist playlist) {
    for (final section in playlist.sections) {
      final count = section.tracks.length;
      if (count < minTracksPerStage || count > maxTracksPerStage) {
        final label = stageLabels[section.stage] ?? section.stage;
        return SafetyBlocked(
          '$label 阶段曲目数需在 $minTracksPerStage-$maxTracksPerStage 首，'
          '当前 $count 首',
        );
      }
    }
    return const SafetyPassed();
  }
}

/// Curator 输出的硬规则组合。
List<SafetyRule<MusicPlaylist>> playlistSafetyRules() => const [
  StageCurveRule(),
  StageBpmRule(),
  TrackCountRule(),
];
