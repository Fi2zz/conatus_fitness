import '../../../../core/logging/app_log.dart';
import '../../domain/music_playlist.dart';
import '../netease/netease_exception.dart';
import 'track_player.dart';
import 'track_player_port.dart';
import 'track_resolver.dart';

/// 解析并播放一首；返回失败原因（成功为 null）。
///
/// 把「音源异常 + 播放器异常」收敛成一条给用户看的文案，控制器据此决定
/// 停在当前曲目。
Future<String?> loadAndPlay(
  TrackResolver resolver,
  TrackPlayerPort player,
  PlaylistTrack track,
) async {
  const String tag = 'playback';
  try {
    final resolution = await resolver.resolve(track);
    final url = resolution.url;
    if (url == null) {
      AppLog.error(tag, '${track.title}：${resolution.message}');
      return resolution.message ?? '取不到播放地址';
    }
    await player.play(url);
    return null;
  } on NeteaseException catch (error, stackTrace) {
    AppLog.error(tag, '音源失败：${track.title}', error, stackTrace);
    return error.message;
  } on TrackPlayerException catch (error, stackTrace) {
    AppLog.error(tag, '播放失败：${track.title}', error, stackTrace);
    return error.message;
  }
}
