import 'package:flutter/cupertino.dart';

import 'mini_player_bar.dart';

/// 把播放条浮在整个 App 之上：挂在 `CupertinoApp.builder`，故退出歌单详情后
/// 仍然可见，且空闲时不占布局。
class PlaybackOverlay extends StatelessWidget {
  const PlaybackOverlay({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ?child,
      const Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(child: MiniPlayerBar()),
      ),
    ],
  );
}
