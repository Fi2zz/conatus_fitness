import 'dart:convert';

import 'package:http/http.dart' as http;

import 'netease_config.dart';
import 'netease_device.dart';
import 'netease_exception.dart';
import 'netease_signer.dart';

/// 开放平台请求的传输层：公共参数 + RSA_SHA256 签名 + 错误映射。
///
/// 业务 code 301 = 匿名令牌被拒（业务接口都要用户授权令牌），转成
/// [NeteaseException.needsLogin] 供 UI 引导登录；其余非 200 原样带出。
class NeteaseTransport {
  NeteaseTransport({
    required this.config,
    required this.device,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  /// 官方 CLI 的请求头（服务端未强校验，保持一致便于比对）。
  static const _headers = <String, String>{
    'User-Agent': 'ncm-0.1.7',
    'Referer': 'https://music.163.com/',
  };

  final NeteaseConfig config;

  /// 设备信息（首次请求时解析，之后复用同一个 Future）。
  final Future<NeteaseDevice> device;

  final http.Client _http;

  /// [post] 为 true 时以 POST 发出（匿名登录），否则 GET。
  Future<Map<String, dynamic>> send(
    String path,
    Map<String, Object?> bizContent,
    String? accessToken, {
    bool post = false,
  }) async {
    // 键序对齐官方客户端（便于与实测流量逐字段比对）。
    final params = <String, String>{
      'appId': config.appId,
      'signType': 'RSA_SHA256',
      'timestamp': '${DateTime.now().millisecondsSinceEpoch}',
      'device': jsonEncode((await device).toJson()),
      'bizContent': jsonEncode(bizContent),
    };
    if (accessToken != null) params['accessToken'] = accessToken;
    params['sign'] = NeteaseSigner.sign(
      NeteaseSigner.canonical(params),
      config.privateKey,
    );
    final uri = Uri.parse(
      '${config.apiBaseUrl}$path',
    ).replace(queryParameters: params);
    final response = post
        ? await _http.post(uri, headers: _headers)
        : await _http.get(uri, headers: _headers);
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw NeteaseException('响应不是 JSON（HTTP ${response.statusCode}）');
    }
    if (body['code'] == 200) return body;
    if (body['code'] == 301) {
      throw const NeteaseException('需要登录网易云账号', needsLogin: true);
    }
    throw NeteaseException(
      '${body['message'] ?? '请求失败'}（code ${body['code']}）',
    );
  }

  void close() => _http.close();
}
