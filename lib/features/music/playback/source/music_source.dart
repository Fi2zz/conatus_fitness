import '../domain/track_ref.dart';

/// 音源端口（架构 6.1 音乐库工具 / 12 播放器）：把策展输出解析成可播放曲目。
///
/// 播放器只依赖本接口；鉴权、签名、接口细节都留在实现里，换音源不动播放器。
abstract interface class MusicSource {
  /// 音源标识，写入 `TrackRef.source`。
  String get id;

  /// 按关键词检索曲目（策展产出只有标题 / 艺人，需先落到音源曲目）。
  Future<List<TrackRef>> search(String keyword, {int limit});

  /// 解析可播放地址；无版权 / 不可播时返回 null。
  Future<Uri?> streamUrl(TrackRef track);

  /// 释放音源持有的资源（HTTP client / 授权态）。
  void dispose();
}