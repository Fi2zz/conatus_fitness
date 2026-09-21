import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/domain_placeholder.dart';
import '../../domain/music_playlist.dart';
import '../providers.dart';
import 'bpm_curve_chart.dart';
import 'playback_launcher.dart';
import 'playlist_section_view.dart';

/// 歌单详情：BPM 曲线 + 分阶段曲目列表（点曲目即入队播放）。
class PlaylistDetailPage extends ConsumerWidget {
  const PlaylistDetailPage({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(playlistDetailProvider(playlistId));
    final playlist = detail.value?.playlist;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('训练歌单'),
        trailing: playlist == null ? null : _playAll(context, ref, playlist),
      ),
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

  Widget _playAll(BuildContext context, WidgetRef ref, MusicPlaylist playlist) {
    final tracks = playlist.allTracks;
    if (tracks.isEmpty) return const SizedBox.shrink();
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => launchPlayback(context, ref, tracks, 0),
      child: const Icon(CupertinoIcons.play_circle),
    );
  }
}

class _PlaylistListView extends ConsumerWidget {
  const _PlaylistListView({required this.playlist});

  final MusicPlaylist playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = playlist.allTracks;
    final children = <Widget>[
      BpmCurveChart(sections: playlist.sections),
      for (final section in playlist.sections)
        PlaylistSectionView(
          section: section,
          onSelect: (track) =>
              launchPlayback(context, ref, queue, queue.indexOf(track)),
        ),
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
    // 底部留出悬浮播放条的位置，避免遮住最后一首。
    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: children,
    );
  }
}
