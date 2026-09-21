import 'dart:async';

import 'package:conatus_fitness/features/music/playback/domain/playback_state.dart';
import 'package:conatus_fitness/features/music/playback/domain/track_ref.dart';
import 'package:conatus_fitness/features/music/playback/player/track_player_port.dart';
import 'package:conatus_fitness/features/music/playback/source/music_source.dart';

/// 假播放器：记录播放过的地址；状态与「播完」事件由测试手动驱动。
class FakeTrackPlayer implements TrackPlayerPort {
  final played = <Uri>[];
  int pauseCount = 0;
  int resumeCount = 0;

  final _statuses = StreamController<PlaybackStatus>.broadcast();
  final _completions = StreamController<void>.broadcast();

  @override
  Stream<PlaybackStatus> get statusStream => _statuses.stream;

  @override
  Stream<void> get completions => _completions.stream;

  @override
  Future<void> play(Uri url) async {
    played.add(url);
    _statuses.add(PlaybackStatus.playing);
  }

  @override
  Future<void> pause() async {
    pauseCount++;
    _statuses.add(PlaybackStatus.paused);
  }

  @override
  Future<void> resume() async {
    resumeCount++;
    _statuses.add(PlaybackStatus.playing);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await _statuses.close();
    await _completions.close();
  }

  /// 模拟当前曲目播完。
  void finishTrack() {
    _statuses.add(PlaybackStatus.idle);
    _completions.add(null);
  }
}

/// 假音源：检索词即曲名（夹具不带艺人），记录被解析过的曲目。
class FakeMusicSource implements MusicSource {
  FakeMusicSource({this.unplayable = const <String>{}});

  /// 命中但取不到地址的曲名（模拟会员曲 / 已下架）。
  final Set<String> unplayable;

  /// 按顺序记录解析过的曲名 = 实际播放顺序。
  final resolved = <String>[];

  @override
  String get id => 'fake';

  @override
  Future<List<TrackRef>> search(String keyword, {int limit = 10}) async => [
    TrackRef(source: id, sourceId: keyword, title: keyword),
  ];

  @override
  Future<Uri?> streamUrl(TrackRef track) async {
    resolved.add(track.sourceId);
    if (unplayable.contains(track.sourceId)) return null;
    return Uri.parse('http://cdn.example/${track.sourceId}.mp3');
  }
}
