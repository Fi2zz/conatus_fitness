import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_log.dart';
import '../../domain/music_playlist.dart';
import '../domain/playback_state.dart';
import '../providers.dart';
import 'playback_queue.dart';
import 'track_loading.dart';

/// 播放控制：UI 的唯一入口。
///
/// 队列 = 整张歌单的全部曲目（阶段顺序）：点某首从那首开始，播完自动续播；
/// 任一环节失败即**停在当前曲目**（不自动跳过），原因由播放条显示，再点即重试。
class PlaybackController extends Notifier<PlaybackState> {
  PlaybackQueue _queue = const PlaybackQueue();
  int _token = 0; // 换歌令牌：丢弃在飞的旧解析结果

  @override
  PlaybackState build() {
    final player = ref.watch(trackPlayerProvider);
    if (player == null) return const PlaybackState();
    final statuses = player.statusStream.listen(_onStatus);
    final completions = player.completions.listen(
      (_) => unawaited(skip(1, auto: true)),
    );
    ref.onDispose(() {
      statuses.cancel();
      completions.cancel();
    });
    return const PlaybackState();
  }

  /// 点选队列第 [index] 首：换歌；再点当前这首则在播放 / 暂停间切换。
  Future<void> playFrom(List<PlaylistTrack> tracks, int index) async {
    if (index < 0 || index >= tracks.length) return;
    final track = tracks[index];
    final resume =
        _queue.index == index && state.isCurrent(track) && state.resumable;
    _queue = PlaybackQueue(tracks: tracks, index: index);
    if (resume) {
      await toggle();
      return;
    }
    await _load(track);
  }

  /// 播放 / 暂停当前曲目（播放条）。
  Future<void> toggle() async {
    final player = ref.read(trackPlayerProvider);
    final track = _queue.current;
    if (player == null || track == null) return;
    switch (state.status) {
      case PlaybackStatus.playing:
        await player.pause();
      case PlaybackStatus.paused:
        await player.resume();
      case PlaybackStatus.loading:
        return;
      case PlaybackStatus.idle || PlaybackStatus.failed:
        await _load(track); // 未载入成功 → 重试当前曲目
    }
  }

  /// 移动队列游标并播放：[step] 为 +1 / -1（播放条上下首）。
  /// [auto] 表示自动续播：到头停住并置空闲；手动跳过则不动。
  Future<void> skip(int step, {bool auto = false}) async {
    final target = _queue.index + step;
    if (target < 0 || target >= _queue.tracks.length) {
      if (auto) state = state.withStatus(PlaybackStatus.idle);
      return;
    }
    _queue = _queue.at(target);
    await _load(_queue.current!);
  }

  Future<void> _load(PlaylistTrack track) async {
    final player = ref.read(trackPlayerProvider);
    final resolver = ref.read(trackResolverProvider);
    if (player == null || resolver == null) {
      AppLog.warn('playback', '音源未装配（网易云 appId / 私钥缺失），无法解析播放地址');
      _fail('还没配置网易云凭证，取不到音源');
      return;
    }
    final token = ++_token;
    state = PlaybackState(status: PlaybackStatus.loading, track: track);
    final failure = await loadAndPlay(resolver, player, track);
    if (token == _token && failure != null) _fail(failure);
  }

  /// idle 只代表播放器未载入，播放意图由控制器持有，故忽略。
  void _onStatus(PlaybackStatus status) {
    if (status != PlaybackStatus.idle) state = state.withStatus(status);
  }

  void _fail(String message) => state = state.failedWith(message);
}
