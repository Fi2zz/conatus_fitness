import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/music_playlist.dart';
import '../../playback/providers.dart';
import 'track_row.dart';

/// 阶段分组：阶段标题 + 曲目行（行内可点播）。
class PlaylistSectionView extends ConsumerWidget {
  const PlaylistSectionView({
    super.key,
    required this.section,
    required this.onSelect,
  });

  final PlaylistSection section;

  /// 点选曲目（队列归属由详情页决定，此处不掺和队列）。
  final void Function(PlaylistTrack track) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackControllerProvider);
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
        for (final track in section.tracks)
          TrackRow(
            track: track,
            isCurrent: playback.isCurrent(track),
            status: playback.status,
            onTap: () => onSelect(track),
          ),
      ],
    );
  }
}
