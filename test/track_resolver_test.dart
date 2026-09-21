import 'package:conatus_fitness/features/music/domain/music_playlist.dart';
import 'package:conatus_fitness/features/music/playback/domain/track_ref.dart';
import 'package:conatus_fitness/features/music/playback/player/track_resolver.dart';
import 'package:conatus_fitness/features/music/playback/source/music_source.dart';
import 'package:flutter_test/flutter_test.dart';

const _curated = PlaylistTrack(
  title: '晴天',
  artist: '周杰伦',
  bpm: 120,
  energy: 0.6,
);

TrackRef _candidate(String title, [String? artist]) =>
    TrackRef(source: 'netease', sourceId: title, title: title, artist: artist);

/// 假音源：候选固定，只有 [playable] 里的曲名能给地址，并记录尝试顺序。
class _FakeSource implements MusicSource {
  _FakeSource({
    this.candidates = const <TrackRef>[],
    this.playable = const <String>{},
  });

  final List<TrackRef> candidates;
  final Set<String> playable;

  String? keyword;
  int? limit;
  final attempted = <String>[];

  @override
  String get id => 'fake';

  @override
  Future<List<TrackRef>> search(String keyword, {int limit = 10}) async {
    this.keyword = keyword;
    this.limit = limit;
    return candidates;
  }

  @override
  Future<Uri?> streamUrl(TrackRef track) async {
    attempted.add(track.sourceId);
    if (!playable.contains(track.sourceId)) return null;
    return Uri.parse('http://cdn.example/${track.sourceId}.mp3');
  }
}

void main() {
  test('检索词是「标题 + 艺人」，命中后返回播放地址', () async {
    final source = _FakeSource(
      candidates: [_candidate('晴天(深情版)', 'Lucky小爱'), _candidate('晴天', '周杰伦')],
      playable: {'晴天'},
    );

    final result = await TrackResolver(source).resolve(_curated);

    expect(result, Uri.parse('http://cdn.example/晴天.mp3'));
    expect(source.keyword, '晴天 周杰伦');
    expect(source.limit, 5);
    expect(source.attempted, ['晴天']); // 首选即命中，不试其它版本
  });

  test('首选不可播（会员曲 / 下架）时换下一个版本', () async {
    final source = _FakeSource(
      candidates: [
        _candidate('晴天', '周杰伦'), // 精确匹配但不可播
        _candidate('晴天(深情版)', 'Lucky小爱'), // 免费版
      ],
      playable: {'晴天(深情版)'},
    );

    final result = await TrackResolver(source).resolve(_curated);

    expect(result, Uri.parse('http://cdn.example/晴天(深情版).mp3'));
    expect(source.attempted, ['晴天', '晴天(深情版)']);
  });

  test('候选都不可播时返回 null，且最多只试 3 个', () async {
    final source = _FakeSource(
      candidates: [
        for (final title in ['晴天', '晴天A', '晴天B', '晴天C']) _candidate(title),
      ],
      playable: {'晴天C'}, // 第 4 个才可播
    );

    expect(await TrackResolver(source).resolve(_curated), isNull);
    expect(source.attempted, hasLength(3));
  });

  test('检索不到任何候选时返回 null', () async {
    final source = _FakeSource(playable: {'晴天'});

    expect(await TrackResolver(source).resolve(_curated), isNull);
  });
}
