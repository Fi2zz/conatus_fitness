import 'package:conatus_fitness/features/music/playback/domain/netease_account.dart';
import 'package:flutter_test/flutter_test.dart';

/// 固定"现在"，避免依赖真实时钟。
final _now = DateTime.fromMillisecondsSinceEpoch(1789970000000);

Map<dynamic, dynamic> _profile(List<Map<String, Object?>> vipDetail) => {
  'nickname': 'afitzz',
  'vipDetail': vipDetail,
};

void main() {
  test('vipDetail 有未过期条目 → 会员有效，取最晚到期时间', () {
    final account = NeteaseAccount.fromProfile(
      _profile([
        {'type': 6, 'expireTime': 1}, // 已过期，忽略
        {'type': 1, 'expireTime': 1789999999000}, // 未来
        {'type': 1, 'expireTime': 1790092799000}, // 更晚
      ]),
      now: _now,
    );

    expect(account.isVip, isTrue);
    expect(
      account.vipExpireAt,
      DateTime.fromMillisecondsSinceEpoch(1790092799000),
    );
    expect(account.nickname, 'afitzz');
  });

  test('vipDetail 为空 / 全部过期 → 非会员', () {
    expect(NeteaseAccount.fromProfile(_profile([]), now: _now).isVip, isFalse);
    expect(
      NeteaseAccount.fromProfile(
        _profile([
          {'type': 1, 'expireTime': 1},
        ]),
        now: _now,
      ).isVip,
      isFalse,
    );
  });

  test('字段缺失 / 类型不符时不炸，按非会员处理', () {
    final account = NeteaseAccount.fromProfile(const <dynamic, dynamic>{});

    expect(account.isVip, isFalse);
    expect(account.vipExpireAt, isNull);
    expect(account.nickname, isNull);
  });
}
