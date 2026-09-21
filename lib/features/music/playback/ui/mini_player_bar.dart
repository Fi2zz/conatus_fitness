import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/playback_state.dart';
import '../providers.dart';
import 'player_bar_action.dart';

/// 悬浮播放条：有当前曲目时浮在所有页面之上（架构 12 的前台 MVP 形态）。
///
/// 空闲时完全不占位、不拦触摸；失败原因显示在副标题位，不弹窗打断。
class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  /// 悬浮高度：留出底部 Tab 栏的空间，免得盖住它。
  static const _bottomInset = 56.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playbackControllerProvider);
    final track = state.track;
    if (track == null) return const SizedBox.shrink();
    final controller = ref.read(playbackControllerProvider.notifier);
    final playing = state.status == PlaybackStatus.playing;
    final loading = state.status == PlaybackStatus.loading;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, _bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
            context,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: CupertinoColors.systemGrey4,
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(child: _label(state, track.title, track.artist)),
              PlayerBarAction(
                icon: CupertinoIcons.backward_end_fill,
                onPressed: () => controller.skip(-1), // 上一首
              ),
              PlayerBarAction(
                icon: playing
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_fill,
                onPressed: controller.toggle,
                enabled: !loading,
              ),
              PlayerBarAction(
                icon: CupertinoIcons.forward_end_fill,
                onPressed: () => controller.skip(1), // 下一首
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(PlaybackState state, String title, String? artist) {
    final failed = state.status == PlaybackStatus.failed;
    final subtitle = state.status == PlaybackStatus.loading
        ? '正在取音源…'
        : state.message ?? artist ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15),
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: failed
                ? CupertinoColors.systemOrange
                : CupertinoColors.secondaryLabel,
          ),
        ),
      ],
    );
  }
}
