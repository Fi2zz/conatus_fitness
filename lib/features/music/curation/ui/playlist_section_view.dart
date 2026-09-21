import 'package:flutter/cupertino.dart';

import '../../domain/music_playlist.dart';

/// 阶段分组：阶段标题 + 曲目行。
class PlaylistSectionView extends StatelessWidget {
  const PlaylistSectionView({super.key, required this.section});

  final PlaylistSection section;

  @override
  Widget build(BuildContext context) {
    final title =
        '${stageLabels[section.stage] ?? section.stage} · ${section.mood}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        for (final track in section.tracks) _TrackRow(track: track),
      ],
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.track});

  final PlaylistTrack track;

  @override
  Widget build(BuildContext context) {
    final artist = track.artist ?? '';
    final reason = track.reason ?? '';
    final subtitle = [
      if (artist.isNotEmpty) artist,
      if (reason.isNotEmpty) reason,
    ].join(' · ');
    return Padding(
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
                  style: const TextStyle(fontSize: 16),
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
        ],
      ),
    );
  }
}
