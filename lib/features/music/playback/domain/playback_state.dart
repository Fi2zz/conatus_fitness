import 'track_ref.dart';

/// 播放状态。
enum PlaybackStatus { idle, loading, playing, paused, failed }

/// 播放器状态快照：UI 的唯一事实源（变更由播放器服务推送）。
class PlaybackState {
  const PlaybackState({
    this.status = PlaybackStatus.idle,
    this.track,
    this.position = Duration.zero,
    this.message,
  });

  final PlaybackStatus status;

  /// 当前（或正在加载）的曲目；空闲时为 null。
  final TrackRef? track;

  /// 当前曲目内的播放位置。
  final Duration position;

  /// 失败原因，仅 [PlaybackStatus.failed] 时有值。
  final String? message;
}