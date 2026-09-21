import 'package:flutter/cupertino.dart';

import '../../domain/music_playlist.dart';
import '../../playback/domain/playback_state.dart';
import 'track_action_icon.dart';

/// 曲目行：BPM 徽章 + 标题 / 艺人 + 播放动作（纯展示，状态由外部传入）。
class TrackRow extends StatelessWidget {
  const TrackRow({
    super.key,
    required this.track,
    required this.onTap,
    required this.isCurrent,
    this.status = PlaybackStatus.idle,
  });

  final PlaylistTrack track;
  final VoidCallback onTap;

  /// 是否是当前这首（决定右侧图标是否点亮）。
  final bool isCurrent;
  final PlaybackStatus status;

  @override
  Widget build(BuildContext context) {
    final artist = track.artist ?? '';
    final reason = track.reason ?? '';
    final subtitle = [
      if (artist.isNotEmpty) artist,
      if (reason.isNotEmpty) reason,
    ].join(' · ');
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 56,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${track.bpm}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemBlue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: isCurrent
                          ? CupertinoColors.systemBlue
                          : CupertinoColors.label,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TrackActionIcon(isCurrent: isCurrent, status: status),
          ],
        ),
      ),
    );
  }
}
