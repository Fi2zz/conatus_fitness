import 'package:conatus_fitness/features/music/domain/music_playlist.dart';
import 'package:conatus_fitness/features/music/playback/providers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/playback_harness.dart';

void main() {
  test('播放条：暂停 / 继续', () async {
    final (container, player, _) = setUpPlayback();
    final controller = container.read(playbackControllerProvider.notifier);

    await controller.playFrom(playbackQueueFixture, 1);
    await pumpEventQueue();
    await controller.toggle();
    await pumpEventQueue();
    expect(player.pauseCount, 1);

    await controller.toggle();
    await pumpEventQueue();
    expect(player.resumeCount, 1);
  });

  test('播放条：下一首 / 上一首；到尽头不动', () async {
    final (container, _, source) = setUpPlayback();
    final controller = container.read(playbackControllerProvider.notifier);

    await controller.playFrom(playbackQueueFixture, 1);
    await pumpEventQueue();
    await controller.skip(1); // 下一首
    await pumpEventQueue();
    expect(container.read(playbackControllerProvider).track?.title, '拉伸曲');

    await controller.skip(1); // 已是最后一首
    await pumpEventQueue();
    expect(source.resolved, ['主项曲', '拉伸曲']);

    await controller.skip(-1); // 上一首
    await pumpEventQueue();
    expect(container.read(playbackControllerProvider).track?.title, '主项曲');
  });

  test('队列顺序 = 阶段顺序（allTracks 拍平）', () {
    final playlist = MusicPlaylist(
      name: '测试歌单',
      notes: '',
      sections: [
        PlaylistSection(
          stage: 'warmup',
          mood: '轻快',
          tracks: [playbackQueueFixture.first],
        ),
        PlaylistSection(
          stage: 'main',
          mood: '强',
          tracks: playbackQueueFixture.sublist(1),
        ),
      ],
    );

    expect(playlist.allTracks.map((track) => track.title), [
      '热身曲',
      '主项曲',
      '拉伸曲',
    ]);
  });
}
