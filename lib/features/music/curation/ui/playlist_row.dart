import 'package:flutter/cupertino.dart';

import '../../../../app.dart';
import '../../../../core/format/date_text.dart';
import '../data/playlists_dao.dart';

/// 歌单列表行：名称 + 曲目数 + 创建日期。
class PlaylistRow extends StatelessWidget {
  const PlaylistRow({super.key, required this.item});

  final StoredPlaylist item;

  @override
  Widget build(BuildContext context) {
    final trackCount = [
      for (final section in item.playlist.sections) ...section.tracks,
    ].length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.of(context).pushNamed(
          AppRoutes.playlistDetail,
          arguments: item.id,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.tertiarySystemGroupedBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.playlist.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$trackCount 首曲目 · ${dateText(item.createdAt)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
