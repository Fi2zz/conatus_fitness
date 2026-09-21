/// 播放层对一首曲目的引用（音源无关）。
///
/// 策展产出的是「是什么歌」（标题 / 艺人 / BPM），播放层要的是「哪个音源的
/// 哪一首」，两者之间由音源检索牵线，故 [TrackRef] 只认音源内的 ID。
class TrackRef {
  const TrackRef({
    required this.source,
    required this.sourceId,
    required this.title,
    this.artist,
    this.playable = true,
  });

  /// 音源标识，与音源的 `id` 对应（如 'netease'）。
  final String source;

  /// 音源内的曲目 ID（网易云为歌曲 id）。
  final String sourceId;

  final String title;

  final String? artist;

  /// 音源声明的可播标记（网易云 search 的 `playFlag`）。
  ///
  /// 实测：`false` 的曲目在开放平台没有播放资源，取地址必然为空（欧美大厂牌
  /// 版权未覆盖的曲目就是这类），故解析时直接跳过，不必浪费请求。
  final bool playable;
}
