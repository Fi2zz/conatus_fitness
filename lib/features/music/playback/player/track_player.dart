import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../domain/playback_state.dart';
import 'track_player_port.dart';

/// 播放失败（把 just_audio 的异常收敛成播放域异常，避免上层依赖该包）。
class TrackPlayerException implements Exception {
  const TrackPlayerException(this.message);

  final String message;

  @override
  String toString() => 'TrackPlayerException: $message';
}

/// 单曲播放器：just_audio 在本仓库的唯一出场点。
///
/// MVP 是「前台单轨播放，队列由控制器持有」；后台播放（audio_service）与
/// AudioArbiter 仲裁留待架构 12 的后续阶段。
class TrackPlayer implements TrackPlayerPort {
  TrackPlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<PlaybackStatus> get statusStream =>
      _player.playerStateStream.map(_map);

  @override
  Stream<void> get completions => _player.processingStateStream
      .where((state) => state == ProcessingState.completed)
      .map((_) {});

  @override
  Future<void> play(Uri url) async {
    try {
      await _player.setUrl(url.toString());
    } on PlayerException catch (error) {
      throw TrackPlayerException(error.message ?? '音源无法播放');
    } on PlayerInterruptedException catch (error) {
      throw TrackPlayerException(error.message ?? '播放被打断');
    }
    unawaited(_player.play()); // play() 播完才返回，故不 await
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.play();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();

  /// 完成态映射到 idle：续播是事件驱动的（见 [completions]），不是状态。
  static PlaybackStatus _map(PlayerState state) =>
      switch (state.processingState) {
        ProcessingState.loading ||
        ProcessingState.buffering => PlaybackStatus.loading,
        ProcessingState.completed ||
        ProcessingState.idle => PlaybackStatus.idle,
        ProcessingState.ready =>
          state.playing ? PlaybackStatus.playing : PlaybackStatus.paused,
      };
}
