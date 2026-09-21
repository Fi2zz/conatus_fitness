import '../../../../core/logging/app_log.dart';
import '../../domain/music_playlist.dart';
import '../source/music_source.dart';
import 'track_match.dart';

/// 解析结果：拿到播放地址，或带一句给用户看的失败原因。
class TrackResolution {
  const TrackResolution._(this.url, this.message);

  const TrackResolution.ok(Uri url) : this._(url, null);

  const TrackResolution.failed(String message) : this._(null, message);

  final Uri? url;

  /// 失败原因，仅失败时有值。
  final String? message;
}

/// 把策展曲目解析成可播放地址。
///
/// 策展产出没有音源 id，故先检索音源再按匹配度**逐首尝试**：音源标记不可播的
/// （`playFlag=false`，开放平台无版权）直接跳过，可播的拿不到地址（会员 / 下架）
/// 就换下一个版本，全试完则给出对应原因。
class TrackResolver {
  TrackResolver(this._source);

  /// 检索条数：够覆盖同曲的版本差异，又不至于拉回一堆无关结果。
  static const _limit = 5;

  /// 最多尝试几个可播候选：换版本有收益，但不想为一次播放打太多次接口。
  static const _attempts = 3;

  static const _noSource = '网易云没有这首歌的可播版本（版权未覆盖或已下架）';
  static const _noAddress = '这首歌取不到播放地址（可能需要会员）';

  final MusicSource _source;

  Future<TrackResolution> resolve(PlaylistTrack track) async {
    final candidates = await _source.search(_keyword(track), limit: _limit);
    final ranked = rankCandidates(
      candidates,
      title: track.title,
      artist: track.artist,
    );
    final playable = [
      for (final candidate in ranked)
        if (candidate.playable) candidate,
    ];
    AppLog.info(
      'playback',
      '解析「${track.title}」：候选 ${ranked.length} 个，可播 ${playable.length} 个',
    );
    if (playable.isEmpty) {
      AppLog.warn('playback', '「${track.title}」无可播候选：$_noSource');
      return const TrackResolution.failed(_noSource);
    }
    for (final candidate in playable.take(_attempts)) {
      final url = await _source.streamUrl(candidate);
      AppLog.info(
        'playback',
        '  ${url != null ? '命中' : '无地址'} ${candidate.title} / '
            '${candidate.artist ?? ''}（${candidate.sourceId}）',
      );
      if (url != null) return TrackResolution.ok(url);
    }
    return const TrackResolution.failed(_noAddress);
  }

  static String _keyword(PlaylistTrack track) =>
      [track.title, track.artist].whereType<String>().join(' ');
}
