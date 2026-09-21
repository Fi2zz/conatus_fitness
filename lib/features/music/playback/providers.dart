import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/playback_state.dart';
import 'netease/netease_music_source.dart';
import 'netease/netease_providers.dart';
import 'player/playback_controller.dart';
import 'player/track_player.dart';
import 'player/track_player_port.dart';
import 'player/track_resolver.dart';
import 'source/music_source.dart';

/// 当前音源装配；未配置 / 未装配时为 null（UI 引导态的判定入口）。
final musicSourceProvider = Provider<MusicSource?>((ref) {
  final client = ref.watch(neteaseClientProvider);
  final auth = ref.watch(neteaseAuthProvider);
  final profile = ref.watch(neteaseProfileProvider);
  if (client == null || auth == null || profile == null) return null;
  return NeteaseMusicSource(client, auth, profile);
});

/// 单曲播放器；音源未配置时为 null（没有音源就没有可播的地址）。
final trackPlayerProvider = Provider<TrackPlayerPort?>((ref) {
  if (ref.watch(musicSourceProvider) == null) return null;
  final player = TrackPlayer();
  ref.onDispose(player.dispose);
  return player;
});

/// 策展曲目 → 可播放地址。
final trackResolverProvider = Provider<TrackResolver?>((ref) {
  final source = ref.watch(musicSourceProvider);
  return source == null ? null : TrackResolver(source);
});

/// 播放控制：UI 唯一入口。
final playbackControllerProvider =
    NotifierProvider<PlaybackController, PlaybackState>(PlaybackController.new);
