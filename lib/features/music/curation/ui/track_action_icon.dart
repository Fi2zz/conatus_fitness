import 'package:flutter/cupertino.dart';

import '../../playback/domain/playback_state.dart';

/// 曲目行的播放动作图标：当前曲目随播放状态变化，其余显示「可播」提示。
class TrackActionIcon extends StatelessWidget {
  const TrackActionIcon({
    super.key,
    required this.isCurrent,
    required this.status,
  });

  final bool isCurrent;
  final PlaybackStatus status;

  @override
  Widget build(BuildContext context) {
    if (!isCurrent) {
      return const Icon(
        CupertinoIcons.play_circle,
        size: 22,
        color: CupertinoColors.tertiaryLabel,
      );
    }
    return switch (status) {
      PlaybackStatus.loading => const CupertinoActivityIndicator(radius: 8),
      PlaybackStatus.playing => const Icon(
        CupertinoIcons.pause_circle_fill,
        size: 22,
        color: CupertinoColors.systemBlue,
      ),
      PlaybackStatus.idle ||
      PlaybackStatus.paused ||
      PlaybackStatus.failed => const Icon(
        CupertinoIcons.play_circle_fill,
        size: 22,
        color: CupertinoColors.systemBlue,
      ),
    };
  }
}
