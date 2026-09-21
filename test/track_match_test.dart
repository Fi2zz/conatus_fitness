import 'package:conatus_fitness/features/music/playback/domain/track_ref.dart';
import 'package:conatus_fitness/features/music/playback/player/track_match.dart';
import 'package:flutter_test/flutter_test.dart';

TrackRef _candidate(String title, [String? artist]) =>
    TrackRef(source: 'netease', sourceId: title, title: title, artist: artist);

/// 排在最前的一首。
TrackRef? _best(
  List<TrackRef> candidates, {
  required String title,
  String? artist,
}) {
  final ranked = rankCandidates(candidates, title: title, artist: artist);
  return ranked.isEmpty ? null : ranked.first;
}

void main() {
  test('标题精确匹配优先于包含匹配', () {
    final best = _best(
      [_candidate('晴天(深情版)', 'Lucky小爱'), _candidate('晴天', '周杰伦')],
      title: '晴天',
      artist: '周杰伦',
    );

    expect(best?.title, '晴天');
  });

  test('音源标题带后缀时，去括号后仍能命中', () {
    final best = _best([
      _candidate('晚安', 'X'),
      _candidate('晴天 (原唱 周杰伦)', 'RyaVocal'),
    ], title: '晴天');

    expect(best?.title, '晴天 (原唱 周杰伦)');
  });

  test('同标题时艺人吻合者胜出', () {
    final best = _best(
      [_candidate('晴天', 'GYBeat'), _candidate('晴天', '周杰伦')],
      title: '晴天',
      artist: '周杰伦',
    );

    expect(best?.artist, '周杰伦');
  });

  test('全部不相关时回落搜索首位（检索词本身就是相关性判断）', () {
    final best = _best(
      [_candidate('完全无关的歌', 'A'), _candidate('另一首', 'B')],
      title: '晴天',
      artist: '周杰伦',
    );

    expect(best?.title, '完全无关的歌');
  });

  test('返回完整降序排列，同分保持服务端原序', () {
    final ranked = rankCandidates(
      [
        _candidate('完全无关的歌', 'A'), // 0 分
        _candidate('晴天(深情版)', 'Lucky小爱'), // 4 分：去括号后标题精确
        _candidate('晴天', '周杰伦'), // 5 分：标题精确 + 艺人吻合
        _candidate('晴天', 'GYBeat'), // 4 分：标题精确
      ],
      title: '晴天',
      artist: '周杰伦',
    );

    expect(
      [for (final track in ranked) '${track.title}/${track.artist}'],
      [
        '晴天/周杰伦',
        '晴天(深情版)/Lucky小爱', // 与下一首同分，靠原序在前
        '晴天/GYBeat',
        '完全无关的歌/A',
      ],
    );
  });

  test('候选为空返回空排列', () {
    expect(rankCandidates(const <TrackRef>[], title: '晴天'), isEmpty);
  });
}
