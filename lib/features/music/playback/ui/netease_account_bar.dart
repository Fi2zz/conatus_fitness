import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/netease_account.dart';
import '../netease/netease_music_source.dart';
import '../netease/netease_providers.dart';

/// 账号条：已登录时显示昵称 + 会员态 + 当前码率；未登录不占位。
class NeteaseAccountBar extends ConsumerWidget {
  const NeteaseAccountBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(neteaseAccountProvider).value;
    if (account == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.person_crop_circle,
            size: 16,
            color: CupertinoColors.secondaryLabel,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _label(account),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 「昵称 · 黑胶VIP（9月22日到期）/ 非会员 · 320kbps」。
  static String _label(NeteaseAccount account) {
    final parts = <String>[
      if (account.nickname != null) account.nickname!,
      if (account.isVip) '黑胶VIP（${_date(account.vipExpireAt!)}到期）' else '非会员',
      '${account.isVip ? NeteaseMusicSource.bitrateVip : NeteaseMusicSource.bitrateFree}kbps',
    ];
    return parts.join(' · ');
  }

  static String _date(DateTime at) => '${at.month}月${at.day}日';
}
