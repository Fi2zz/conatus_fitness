import 'package:conatus_fitness/features/music/domain/music_playlist.dart';
import 'package:conatus_fitness/features/music/playback/player/track_resolver.dart';
import 'package:conatus_fitness/features/music/playback/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'playback_fakes.dart';

/// 队列夹具（夹具不带艺人，故检索词即曲名）。
final playbackQueueFixture = <PlaylistTrack>[
  _track('热身曲'),
  _track('主项曲'),
  _track('拉伸曲'),
];

PlaylistTrack _track(String title) =>
    PlaylistTrack(title: title, bpm: 120, energy: 0.5);

/// 把播放器与解析器换成假实现：不需要真音源、真音频即可跑队列逻辑。
(ProviderContainer, FakeTrackPlayer, FakeMusicSource) setUpPlayback({
  Set<String> unplayable = const <String>{},
}) {
  final player = FakeTrackPlayer();
  final source = FakeMusicSource(unplayable: unplayable);
  final container = ProviderContainer(
    overrides: [
      trackPlayerProvider.overrideWithValue(player),
      trackResolverProvider.overrideWithValue(TrackResolver(source)),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(player.dispose);
  return (container, player, source);
}