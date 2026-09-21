import '../../../../core/logging/app_log.dart';
import '../../domain/music_playlist.dart';
import '../source/music_source.dart';
import 'track_match.dart';

/// 把策展曲目解析成可播放地址。
///
/// 策展产出没有音源 id，故先检索音源、再按匹配度**逐首尝试**：会员曲 / 已下架
/// 拿不到地址就换下一个版本（同一首歌常有免费版或翻唱），全试完仍失败才返回
/// null，由控制器转成给用户的提示。
class TrackResolver {
  TrackResolver(this._source);

  /// 检索条数：够覆盖同曲的版本差异，又不至于拉回一堆无关结果。
  static const _limit = 5;

  /// 最多尝试几个候选：换版本有收益，但不想为一次播放打太多次接口。
  static const _attempts = 3;

  final MusicSource _source;

  Future<Uri?> resolve(PlaylistTrack track) async {
    final candidates = await _source.search(_keyword(track), limit: _limit);
    final ranked = rankCandidates(
      candidates,
      title: track.title,
      artist: track.artist,
    );
    AppLog.info(
      'playback',
      '解析「${track.title}」：候选 ${ranked.length} 个，尝试前 $_attempts',
    );
    for (final candidate in ranked.take(_attempts)) {
      final url = await _source.streamUrl(candidate);
      AppLog.info(
        'playback',
        '  ${url != null ? '命中' : '不可播'} ${candidate.title} / '
            '${candidate.artist ?? ''}（${candidate.sourceId}）',
      );
      if (url != null) return url;
    }
    return null;
  }

  static String _keyword(PlaylistTrack track) =>
      [track.title, track.artist].whereType<String>().join(' ');
}
