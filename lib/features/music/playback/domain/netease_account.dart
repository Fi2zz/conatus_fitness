/// 网易云账号快照：昵称 + 会员态（播放码率据此选择）。
///
/// 会员判定只看 `vipDetail` 里的 `expireTime`（毫秒时间戳，实测）：任一条未过期
/// 即会员有效。`type`（实测见到 1 / 6）含义未确认，故不参与判定。
class NeteaseAccount {
  const NeteaseAccount({this.nickname, this.isVip = false, this.vipExpireAt});

  /// 从 `user/profile/get/v2` 的 `data` 解析；[now] 便于测试注入。
  factory NeteaseAccount.fromProfile(
    Map<dynamic, dynamic> data, {
    DateTime? now,
  }) {
    final DateTime at = now ?? DateTime.now();
    DateTime? expireAt;
    final details = data['vipDetail'];
    if (details is List) {
      for (final item in details) {
        final Object? expire = item is Map ? item['expireTime'] : null;
        if (expire is! int) continue;
        final DateTime when = DateTime.fromMillisecondsSinceEpoch(expire);
        if (!when.isAfter(at)) continue;
        if (expireAt == null || when.isAfter(expireAt)) expireAt = when;
      }
    }
    final nickname = data['nickname'];
    return NeteaseAccount(
      nickname: nickname is String && nickname.isNotEmpty ? nickname : null,
      isVip: expireAt != null,
      vipExpireAt: expireAt,
    );
  }

  final String? nickname;
  final bool isVip;

  /// 会员到期时间（非会员为 null）。
  final DateTime? vipExpireAt;
}
