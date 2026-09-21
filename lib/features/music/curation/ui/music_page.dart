import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app.dart';
import '../../../../di/llm_providers.dart';
import '../../../common/domain_placeholder.dart';
import '../../playback/netease/netease_providers.dart';
import '../../playback/ui/netease_account_bar.dart';
import '../providers.dart';
import 'playlist_row.dart';

/// 音乐域首页：AI 策展歌单列表 + 生成入口。
class MusicPage extends ConsumerWidget {
  const MusicPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(llmStatusProvider);
    final body = switch (status) {
      // 读盘期与内容加载同形（转圈），避免启动时闪引导态。
      LlmStatus.loading => const Center(child: CupertinoActivityIndicator()),
      LlmStatus.notConfigured => const DomainPlaceholder(
        icon: CupertinoIcons.lock_circle,
        title: 'AI 训练音乐',
        subtitle: '在「我的 → 模型接入」填好 Base URL 与 API Key 后即可使用',
      ),
      LlmStatus.ready => _playlistsBody(ref),
    };
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('音乐'),
        automaticallyImplyLeading: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == LlmStatus.ready) _addAction(context),
            _loginAction(context, ref),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const NeteaseAccountBar(),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _addAction(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.playlistSetup),
      child: const Icon(CupertinoIcons.add_circled),
    );
  }

  /// 网易云登录入口：未登录显示文字，已登录显示头像图标（点了可重新登录）。
  Widget _loginAction(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(neteaseLoggedInProvider).value ?? false;
    return CupertinoButton(
      padding: EdgeInsets.only(left: 12),
      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.neteaseLogin),
      child: loggedIn
          ? const Icon(CupertinoIcons.person_circle)
          : const Text('登录'),
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
