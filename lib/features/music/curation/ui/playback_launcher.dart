import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app.dart';
import '../../domain/music_playlist.dart';
import '../../playback/netease/netease_providers.dart';
import '../../playback/providers.dart';

/// 播放前确保已登录网易云：未登录先去授权页，授权成功再继续原动作。
///
/// 接口一律要用户令牌，匿名态下搜索 / 取播放地址都会被服务端拒绝，
/// 故登录检查放在播放入口而不是等失败再提示。
Future<void> launchPlayback(
  BuildContext context,
  WidgetRef ref,
  List<PlaylistTrack> tracks,
  int index,
) async {
  if (!await ref.read(neteaseLoggedInProvider.future)) {
    if (!context.mounted) return;
    final authorized = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.neteaseLogin);
    if (authorized != true) return;
  }
  if (!context.mounted) return;
  await ref.read(playbackControllerProvider.notifier).playFrom(tracks, index);
}
