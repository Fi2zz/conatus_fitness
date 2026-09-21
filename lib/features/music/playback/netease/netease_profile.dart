import '../../../../core/logging/app_log.dart';
import '../domain/netease_account.dart';
import 'netease_auth.dart';
import 'netease_client.dart';
import 'netease_exception.dart';

/// 账号资料：会员态按进程缓存一次，登录态变化时 [invalidate] 重取。
///
/// 拿不到资料不是错误 —— 未登录或接口失败都返回 null，播放退到默认码率。
class NeteaseProfile {
  NeteaseProfile({required this.client, required this.auth});

  static const _path = '/openapi/music/basic/user/profile/get/v2';

  final NeteaseClient client;
  final NeteaseAuth auth;

  NeteaseAccount? _cached;

  /// 账号资料；未登录 / 取不到时为 null（不缓存失败）。
  Future<NeteaseAccount?> account() async {
    final cached = _cached;
    if (cached != null) return cached;
    if (!await auth.loggedIn()) return null;
    try {
      final body = await client.get(
        _path,
        const <String, Object?>{},
        await auth.accessToken(),
      );
      final data = body['data'];
      if (data is! Map) return null;
      return _cached = NeteaseAccount.fromProfile(data);
    } on NeteaseException catch (error, stackTrace) {
      AppLog.warn('netease_profile', '读取账号资料失败，按非会员处理', error, stackTrace);
      return null;
    }
  }

  /// 登录态变化后调用。
  void invalidate() => _cached = null;
}
