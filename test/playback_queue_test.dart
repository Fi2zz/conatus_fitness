import 'package:conatus_fitness/features/music/playback/domain/playback_state.dart';
import 'package:conatus_fitness/features/music/playback/providers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/playback_harness.dart';

void main() {
  test('点第一首：解析并播放队列首曲', () async {
    final (container, player, source) = setUpPlayback();

    await container
        .read(playbackControllerProvider.notifier)
        .playFrom(playbackQueueFixture, 0);
    await pumpEventQueue();

    expect(source.resolved, ['热身曲']);
    expect(player.played.single, Uri.parse('http://cdn.example/热身曲.mp3'));
    final state = container.read(playbackControllerProvider);
    expect(state.track?.title, '热身曲');
    expect(state.status, PlaybackStatus.playing);
  });

  test('播完自动续播下一首', () async {
    final (container, player, source) = setUpPlayback();
    final controller = container.read(playbackControllerProvider.notifier);

    await controller.playFrom(playbackQueueFixture, 0);
    await pumpEventQueue();
    player.finishTrack();
    await pumpEventQueue();

    expect(source.resolved, ['热身曲', '主项曲']);
    expect(player.played, hasLength(2));
    expect(container.read(playbackControllerProvider).track?.title, '主项曲');
  });

  test('最后一首播完即停在当前曲目（不再解析）', () async {
    final (container, player, source) = setUpPlayback();
    final controller = container.read(playbackControllerProvider.notifier);

    await controller.playFrom(playbackQueueFixture, 2);
    await pumpEventQueue();
    player.finishTrack();
    await pumpEventQueue();

    expect(source.resolved, ['拉伸曲']);
    final state = container.read(playbackControllerProvider);
    expect(state.status, PlaybackStatus.idle);
    expect(state.track?.title, '拉伸曲');
  });

  test('某首失败：停在该曲，不自动跳下一首也不弹窗', () async {
    final (container, player, source) = setUpPlayback(unplayable: {'主项曲'});
    final controller = container.read(playbackControllerProvider.notifier);

    await controller.playFrom(playbackQueueFixture, 0);
    await pumpEventQueue();
    player.finishTrack();
    await pumpEventQueue();

    final state = container.read(playbackControllerProvider);
    expect(state.status, PlaybackStatus.failed);
    expect(state.track?.title, '主项曲');
    expect(state.message, isNotNull);
    expect(source.resolved, ['热身曲', '主项曲']); // 未继续解析第三首
    expect(player.played, hasLength(1));
  });

  test('失败后再点同一首即重试', () async {
    final (container, player, source) = setUpPlayback(unplayable: {'热身曲'});
    final controller = container.read(playbackControllerProvider.notifier);

    await controller.playFrom(playbackQueueFixture, 0);
    await pumpEventQueue();
    expect(
      container.read(playbackControllerProvider).status,
      PlaybackStatus.failed,
    );

    await controller.playFrom(playbackQueueFixture, 0);
    await pumpEventQueue();

    expect(source.resolved, ['热身曲', '热身曲']);
    expect(player.played, isEmpty);
  });
}
