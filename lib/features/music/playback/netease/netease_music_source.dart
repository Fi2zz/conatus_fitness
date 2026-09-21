import '../../../../core/logging/app_log.dart';
import '../domain/track_ref.dart';
import '../source/music_source.dart';
import 'netease_auth.dart';
import 'netease_client.dart';
import 'netease_profile.dart';

/// 网易云音乐音源（开放平台，个人开发者认证）。
///
/// 请求形状对齐官方 CLI 的实测流量：GET + `trialScene: cli` 的业务参数；
/// 接口需要用户授权令牌（匿名令牌一律 301），未登录时报
/// [NeteaseException.needsLogin] 由调用方引导登录。码率按会员态选：
/// 会员 320kbps，非会员 128kbps（对齐官方 CLI 的默认档）。
class NeteaseMusicSource implements MusicSource {
  NeteaseMusicSource(this._client, this._auth, this._profile);

  static const _searchPath = '/openapi/music/basic/search/song/get/v3';
  static const _detailPath = '/openapi/music/basic/song/detail/get/v2';
  static const _scene = 'cli';
  static const bitrateFree = 128;
  static const bitrateVip = 320;

  final NeteaseClient _client;
  final NeteaseAuth _auth;
  final NeteaseProfile _profile;

  @override
  String get id => 'netease';

  /// 关键词检索：返回音源曲目（sourceId 为开放平台的加密 id）。
  @override
  Future<List<TrackRef>> search(String keyword, {int limit = 10}) async {
    final body = await _client.get(_searchPath, <String, Object?>{
      'keyword': keyword,
      'limit': limit,
      'offset': 0,
      'qualityFlag': false,
      'trialScene': _scene,
    }, await _auth.accessToken());
    final records = (body['data'] as Map?)?['records'];
    if (records is! List) return const <TrackRef>[];
    return [
      for (final record in records)
        if (record is Map) _toTrack(record),
    ];
  }

  /// 播放地址；VIP / 无版权时开放平台下发 null，此处同样返回 null。
  @override
  Future<Uri?> streamUrl(TrackRef track) async {
    final vip = (await _profile.account())?.isVip ?? false;
    final bitrate = vip ? bitrateVip : bitrateFree;
    final body = await _client.get(_detailPath, <String, Object?>{
      'songId': track.sourceId,
      'withUrl': true,
      'bitrate': bitrate,
      'trialScene': _scene,
    }, await _auth.accessToken());
    final data = body['data'] as Map?;
    final url = data?['playUrl'];
    // 服务端为何不给地址（会员 / 无版权 / 未获授权）只能从这里看出来。
    AppLog.info(
      'netease',
      'detail ${track.title}｜${bitrate}kbps｜playUrl=${url != null}'
          '｜playFlag=${data?['playFlag']}｜vipFlag=${data?['vipFlag']}'
          '｜level=${data?['level']}｜br=${data?['br']}',
    );
    if (url is! String || url.isEmpty) return null;
    return Uri.tryParse(url);
  }

  TrackRef _toTrack(Map<dynamic, dynamic> record) => TrackRef(
    source: id,
    sourceId: '${record['id']}',
    title: '${record['name']}',
    artist: _artists(record),
  );

  static String? _artists(Map<dynamic, dynamic> record) {
    final names = _names(record['artists']);
    // 已下线艺人只在 fullArtists 里带名字，故 artists 为空时回落。
    final resolved = names.isEmpty ? _names(record['fullArtists']) : names;
    return resolved.isEmpty ? null : resolved.join(' / ');
  }

  static List<String> _names(Object? artists) {
    if (artists is! List) return const <String>[];
    return [
      for (final artist in artists)
        if (artist is Map && artist['name'] is String) artist['name'] as String,
    ];
  }
}
