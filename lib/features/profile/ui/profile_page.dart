import 'package:flutter/cupertino.dart';

import '../../common/domain_placeholder.dart';

/// 我的页：用户画像、隐私控制与语音记录管理入口。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('我的'),
        automaticallyImplyLeading: false,
      ),
      child: const SafeArea(
        child: DomainPlaceholder(
          icon: CupertinoIcons.person_crop_circle,
          title: '个人画像',
          subtitle: '目标、器械条件、伤病史与隐私设置',
        ),
      ),
    );
  }
}
