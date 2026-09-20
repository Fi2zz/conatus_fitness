import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/domain_placeholder.dart';
import '../domain/music_playlist.dart';
import '../providers.dart';
import 'bpm_curve_chart.dart';
import 'playlist_section_view.dart';

/// 歌单详情：BPM 曲线 + 分阶段曲目列表。
class PlaylistDetailPage extends ConsumerWidget {
  const PlaylistDetailPage({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(playlistDetailProvider(playlistId));
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('训练歌单')),
      child: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, _) => const DomainPlaceholder(
            icon: CupertinoIcons.exclamationmark_triangle,
            title: '加载失败',
            subtitle: '请返回后重试',
          ),
          data: (stored) {
            if (stored == null) {
              return const DomainPlaceholder(
                icon: CupertinoIcons.doc_text_search,
                title: '歌单不存在',
                subtitle: '该歌单可能已被删除',
              );
            }
            return _PlaylistListView(playlist: stored.playlist);
          },
        ),
      ),
    );
  }
}

class _PlaylistListView extends StatelessWidget {
  const _PlaylistListView({required this.playlist});

  final MusicPlaylist playlist;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      BpmCurveChart(sections: playlist.sections),
      for (final section in playlist.sections)
        PlaylistSectionView(section: section),
    ];
    if (playlist.notes.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '策展思路：${playlist.notes}',
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
      );
    }
    return ListView(children: children);
  }
}
