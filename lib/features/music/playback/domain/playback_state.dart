import '../../domain/music_playlist.dart';

/// 播放状态。
enum PlaybackStatus { idle, loading, playing, paused, failed }

/// 播放器状态快照：UI 的唯一事实源。
class PlaybackState {
  const PlaybackState({
    this.status = PlaybackStatus.idle,
    this.track,
    this.message,
  });

  final PlaybackStatus status;

  /// 当前（或正在加载）的策展曲目；空闲时为 null。
  final PlaylistTrack? track;

  /// 失败原因，仅 [PlaybackStatus.failed] 时有值。
  final String? message;

  /// 是否就是这首（按标题 + 艺人判定）：换歌与暂停/继续的分支依据。
  bool isCurrent(PlaylistTrack other) {
    final current = track;
    return current != null &&
        current.title == other.title &&
        current.artist == other.artist;
  }

  /// 是否处于可续播态（点当前曲目即切换播放 / 暂停）。
  bool get resumable =>
      status == PlaybackStatus.playing || status == PlaybackStatus.paused;

  /// 同一首曲目的新状态快照。
  PlaybackState withStatus(PlaybackStatus next) =>
      PlaybackState(status: next, track: track);

  /// 失败快照：保留当前曲目，便于再点即重试。
  PlaybackState failedWith(String reason) => PlaybackState(
    status: PlaybackStatus.failed,
    track: track,
    message: reason,
  );
}
