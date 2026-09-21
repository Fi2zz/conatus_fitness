import 'package:conatus/conatus.dart';

import '../domain/login_ticket.dart';
import 'netease_client.dart';
import 'netease_exception.dart';

/// 登录态：用户授权令牌优先，未登录时业务接口只能拿到匿名令牌（必被拒）。
///
/// 令牌落 flutter_secure_storage（[Credentials]），与 LLM 密钥同一口径；
/// 匿名令牌只用于申请登录票据与轮询授权结果。
class NeteaseAuth {
  NeteaseAuth({required this.client, required this.credentials});

  /// 用户令牌的存储键（snake_case）。
  static const tokenKey = 'netease_access_token';

  final NeteaseClient client;

  /// 凭据服务（读盘完成才可用，故传 Future）。
  final Future<Credentials> credentials;

  /// 是否已登录。
  Future<bool> loggedIn() async => await _storedToken() != null;

  /// 业务接口令牌。
  Future<String> accessToken() async =>
      await _storedToken() ?? client.anonymousToken();

  /// 申请票据：拿授权网页地址与轮询键。
  Future<NeteaseLoginTicket> requestTicket() async {
    final data = (await client.ticket())['data'];
    final key = data is Map ? data['uniKey'] : null;
    if (key is! String || key.isEmpty) {
      throw const NeteaseException('登录票据返回异常');
    }
    return NeteaseLoginTicket(
      url: (await client.loginUrl(key)).toString(),
      uniKey: key,
    );
  }

  /// 轮询一次授权结果；授权成功即落盘。
  Future<TicketPoll> pollTicket(NeteaseLoginTicket ticket) async {
    final data = (await client.pollTicket(ticket.uniKey))['data'];
    if (data is! Map) return (status: LoginTicketStatus.pending, message: null);
    final message = data['msg'] as String?;
    final token = _issuedToken(data);
    if (token != null) {
      await (await credentials).update(tokenKey, token);
      return (status: LoginTicketStatus.authorized, message: message);
    }
    return (
      status: data['status'] == 800
          ? LoginTicketStatus.expired
          : LoginTicketStatus.pending,
      message: message,
    );
  }

  /// 取出新下发的用户令牌。
  ///
  /// 实测授权成功（803）时 `accessToken` 是对象
  /// `{accessToken, refreshToken, expireTime, scopes}`，未授权时为 null；
  /// 匿名登录那条接口下发的则是裸字符串，故两种形状都认。
  static String? _issuedToken(Map<dynamic, dynamic> data) {
    final raw = data['accessToken'];
    final token = raw is Map ? raw['accessToken'] : raw;
    return token is String && token.isNotEmpty ? token : null;
  }

  /// 退出登录（清空令牌，退回匿名态）。
  Future<void> signOut() async => (await credentials).update(tokenKey, '');

  Future<String?> _storedToken() async {
    final token = (await credentials).get(tokenKey)?.value;
    return (token == null || token.isEmpty) ? null : token;
  }
}
