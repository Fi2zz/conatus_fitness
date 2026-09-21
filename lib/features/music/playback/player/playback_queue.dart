import '../../domain/music_playlist.dart';

/// 播放队列：曲目 + 当前游标（纯数据；游标越界即「已到尽头」）。
class PlaybackQueue {
  const PlaybackQueue({this.tracks = const <PlaylistTrack>[], this.index = -1});

  final List<PlaylistTrack> tracks;
  final int index;

  PlaylistTrack? get current =>
      index >= 0 && index < tracks.length ? tracks[index] : null;

  bool get hasNext => index + 1 < tracks.length;

  bool get hasPrevious => index > 0;

  PlaybackQueue at(int index) => PlaybackQueue(tracks: tracks, index: index);
}
