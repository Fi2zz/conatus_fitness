import 'package:http/http.dart' as http;

import 'netease_config.dart';
import 'netease_device.dart';
import 'netease_exception.dart';
import 'netease_transport.dart';

/// 开放平台接口封装：匿名身份、授权登录（票据 + 轮询）、业务接口。
///
/// 匿名令牌只够拉起授权登录，业务接口一律要用户令牌（见 `NeteaseAuth`）。
class NeteaseClient {
  NeteaseClient({
    required NeteaseConfig config,
    required Future<NeteaseDevice> device,
    http.Client? httpClient,
  }) : _transport = NeteaseTransport(
         config: config,
         device: device,
         httpClient: httpClient,
       );

  static const _anonymousPath = '/openapi/music/basic/oauth2/login/anonymous';
  static const _ticketPath =
      '/openapi/music/basic/user/oauth2/qrcodekey/get/v2';
  static const _pollPath =
      '/openapi/music/basic/oauth2/device/login/qrcode/get';
  static const _loginPage = 'https://music.163.com/st/platform/scanlogin';

  final NeteaseTransport _transport;
  String? _anonymousToken;

  /// 匿名令牌（进程内复用）。
  Future<String> anonymousToken() async {
    final String? cached = _anonymousToken;
    if (cached != null) return cached;
    final body = await _transport.send(
      _anonymousPath,
      <String, Object?>{'clientId': _transport.config.appId},
      null,
      post: true,
    );
    final token = (body['data'] as Map?)?['accessToken'];
    if (token is! String || token.isEmpty) {
      throw const NeteaseException('匿名登录未返回 accessToken');
    }
    return _anonymousToken = token;
  }

  /// 登录票据：待授权的网页地址 + 轮询键。
  Future<Map<String, dynamic>> ticket() async => _transport.send(
    _ticketPath,
    <String, Object?>{'type': 2, 'expiredKey': '300'},
    await anonymousToken(),
  );

  /// 授权登录网页：由票据 uniKey + 设备 + appId 拼出。
  ///
  /// 服务端只回一个短链，这里按短链落地页的参数原样拼（实测与服务端跳转的
  /// query 逐字节一致），免得依赖短链跳转那一跳。
  Future<Uri> loginUrl(String uniKey) async {
    final info = await _transport.device;
    return Uri.parse(_loginPage).replace(
      queryParameters: <String, String>{
        'codekey': uniKey,
        'hdw_deviceid': info.deviceId,
        'hdw_device': NeteaseDevice.deviceType,
        'hdw_brand': NeteaseDevice.brand,
        'hdw_model': NeteaseDevice.model,
        'hdw_appid': _transport.config.appId,
        'hitExp': '1',
      },
    );
  }

  /// 轮询一次授权结果（status：801 等待 / 802 待确认 / 803 成功 / 800 过期）。
  Future<Map<String, dynamic>> pollTicket(String uniKey) async =>
      _transport.send(_pollPath, <String, Object?>{
        'key': uniKey,
        'clientId': _transport.config.appId,
      }, await anonymousToken());

  /// 业务接口（`accessToken` 传用户令牌；未登录会被服务端拒绝）。
  Future<Map<String, dynamic>> get(
    String path,
    Map<String, Object?> bizContent,
    String accessToken,
  ) => _transport.send(path, bizContent, accessToken);

  void close() => _transport.close();
}
