import 'package:flutter/cupertino.dart';

import '../music/ui/music_page.dart';
import '../profile/ui/profile_page.dart';
import '../training/ui/training_page.dart';

/// 底部三 Tab 壳：训练 / 音乐 / 我的。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final CupertinoTabController _controller = CupertinoTabController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: _controller,
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.bolt), label: '训练'),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.music_note),
            label: '音乐',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_crop_circle),
            label: '我的',
          ),
        ],
      ),
      tabBuilder: (context, index) => switch (index) {
        0 => const TrainingPage(),
        1 => const MusicPage(),
        _ => const ProfilePage(),
      },
    );
  }
}
