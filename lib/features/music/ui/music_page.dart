import 'package:flutter/cupertino.dart';

import '../../common/domain_placeholder.dart';

/// 音乐域首页。Phase 3 起落地：MusicCurator 歌单 + 播放器。
class MusicPage extends StatelessWidget {
  const MusicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('音乐'),
        automaticallyImplyLeading: false,
      ),
      child: const SafeArea(
        child: DomainPlaceholder(
          icon: CupertinoIcons.music_note,
          title: '训练音乐',
          subtitle: '按训练阶段 BPM 曲线策展歌单，DJ 实时跟随（Phase 3-4）',
        ),
      ),
    );
  }
}
