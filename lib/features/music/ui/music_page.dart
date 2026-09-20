import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app.dart';
import '../../../di/llm_providers.dart';
import '../../common/domain_placeholder.dart';
import '../providers.dart';
import 'playlist_row.dart';

/// 音乐域首页：AI 策展歌单列表 + 生成入口。
class MusicPage extends ConsumerWidget {
  const MusicPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(llmReadyProvider);
    Widget body;
    if (!ready) {
      body = const DomainPlaceholder(
        icon: CupertinoIcons.lock_circle,
        title: 'AI 训练音乐',
        subtitle: '通过 --dart-define 注入 ARK_API_KEY 与 ARK_BASE_URL 后即可使用',
      );
    } else {
      body = _playlistsBody(ref);
    }
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('音乐'),
        automaticallyImplyLeading: false,
        trailing: ready ? _addAction(context) : null,
      ),
      child: SafeArea(child: body),
    );
  }

  Widget _addAction(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.playlistSetup),
      child: const Icon(CupertinoIcons.add_circled),
    );
  }

  Widget _playlistsBody(WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    return playlists.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, _) => const DomainPlaceholder(
        icon: CupertinoIcons.exclamationmark_triangle,
        title: '加载失败',
        subtitle: '请返回后重试',
      ),
      data: (items) {
        if (items.isEmpty) {
          return const DomainPlaceholder(
            icon: CupertinoIcons.music_note,
            title: '训练歌单',
            subtitle: '按训练阶段 BPM 曲线策展专属歌单，点右上角开始',
          );
        }
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [for (final item in items) PlaylistRow(item: item)],
        );
      },
    );
  }
}
