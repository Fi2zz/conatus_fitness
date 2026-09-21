import '../domain/playback_state.dart';

/// 播放器端口：控制器只依赖它。
///
/// 这样队列与续播逻辑可以用假实现跑测试，也便于后续换引擎或加 AudioArbiter
/// 仲裁（架构 12）而不动控制器。
abstract interface class TrackPlayerPort {
  /// 播放状态流（供 UI 展示）。
  Stream<PlaybackStatus> get statusStream;

  /// 单曲播放完成事件（自动续播的触发源；是事件不是状态）。
  Stream<void> get completions;

  /// 载入并播放；失败抛异常（实现方收敛成自己的异常类型）。
  Future<void> play(Uri url);

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<void> dispose();
}
