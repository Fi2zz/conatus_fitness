import '../domain/track_ref.dart';
import '../source/music_source.dart';
import 'netease_config.dart';

/// 网易云音乐音源（开放平台，个人开发者认证）。
///
/// 骨架：端口已定，协议实现待接口清单确认后补齐 —— 开放平台的每个请求都要
/// 带 appId + timestamp + accessToken + 签名，签名算法与接口路径以开放平台
/// 文档为准，实现前不猜。
class NeteaseMusicSource implements MusicSource {
  NeteaseMusicSource(this.config);

  final NeteaseConfig config;

  @override
  String get id => 'netease';

  @override
  Future<List<TrackRef>> search(String keyword, {int limit = 10}) =>
      throw UnimplementedError('待接入开放平台搜索接口');

  @override
  Future<Uri?> streamUrl(TrackRef track) =>
      throw UnimplementedError('待接入开放平台播放地址接口');

  @override
  void dispose() {}
}