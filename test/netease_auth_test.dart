import 'package:conatus/conatus.dart';
import 'package:conatus_fitness/features/music/playback/domain/login_ticket.dart';
import 'package:conatus_fitness/features/music/playback/netease/netease_auth.dart';
import 'package:conatus_fitness/features/music/playback/netease/netease_client.dart';
import 'package:conatus_fitness/features/music/playback/netease/netease_config.dart';
import 'package:conatus_fitness/features/music/playback/netease/netease_device.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/netease_fixtures.dart';

const _config = NeteaseConfig(
  appId: 'a301010000000000aadb4e5a28b45a67',
  privateKey: neteaseTestPrivateKey,
);

const _jsonHeaders = <String, String>{
  'content-type': 'application/json; charset=utf-8',
};

/// 组装 auth + 请求记录 + 凭据（[token] 为已登录令牌）。
(NeteaseAuth, List<Uri>, InMemoryCredentials) _auth({
  String poll = neteasePendingTicketResponse,
  String? token,
}) {
  final calls = <Uri>[];
  final client = NeteaseClient(
    config: _config,
    device: Future.value(const NeteaseDevice(deviceId: 'conatus_test')),
    httpClient: MockClient((request) async {
      calls.add(request.url);
      final path = request.url.path;
      if (path.endsWith('/oauth2/login/anonymous')) {
        return http.Response(
          neteaseAnonymousLoginResponse,
          200,
          headers: _jsonHeaders,
        );
      }
      if (path.endsWith('/qrcodekey/get/v2')) {
        return http.Response(neteaseTicketResponse, 200, headers: _jsonHeaders);
      }
      if (path.endsWith('/device/login/qrcode/get')) {
        return http.Response(poll, 200, headers: _jsonHeaders);
      }
      return http.Response('{"code":404}', 404, headers: _jsonHeaders);
    }),
  );
  final credentials = InMemoryCredentials(
    initial: token == null
        ? const <String, String>{}
        : {NeteaseAuth.tokenKey: token},
  );
  return (
    NeteaseAuth(client: client, credentials: Future.value(credentials)),
    calls,
    credentials,
  );
}

void main() {
  test('requestTicket：用匿名令牌取轮询键，并本地拼出授权网页地址', () async {
    final (auth, calls, _) = _auth();

    final ticket = await auth.requestTicket();

    expect(ticket.uniKey, 'demo-uni-key');
    final url = Uri.parse(ticket.url);
    expect(url.path, '/st/platform/scanlogin');
    expect(url.queryParameters['codekey'], 'demo-uni-key');
    expect(url.queryParameters['hdw_deviceid'], 'conatus_test');
    expect(url.queryParameters['hdw_appid'], _config.appId);
    expect(url.queryParameters['hdw_device'], 'openapi');
    expect(calls.first.path, endsWith('/oauth2/login/anonymous'));
    expect(calls.last.path, endsWith('/qrcodekey/get/v2'));
    expect(calls.last.queryParameters['bizContent'], contains('"type":2'));
  });

  test('pollTicket：等待授权时返回 pending 与服务端文案，不落令牌', () async {
    final (auth, _, credentials) = _auth();

    final result = await auth.pollTicket(
      const NeteaseLoginTicket(url: 'https://163cn.tv/demo', uniKey: 'k'),
    );

    expect(result.status, LoginTicketStatus.pending);
    expect(result.message, '等待扫码');
    expect(credentials.get(NeteaseAuth.tokenKey), isNull);
    expect(await auth.loggedIn(), isFalse);
  });

  test('pollTicket：授权成功后（accessToken 为对象）落盘用户令牌', () async {
    final (auth, calls, credentials) = _auth(
      poll: neteaseAuthorizedTicketResponse,
    );

    final result = await auth.pollTicket(
      const NeteaseLoginTicket(url: 'https://163cn.tv/demo', uniKey: 'k'),
    );

    expect(result.status, LoginTicketStatus.authorized);
    expect(result.message, '扫码成功');
    expect(credentials.get(NeteaseAuth.tokenKey)?.value, 'tbdemo-user-token');
    expect(await auth.loggedIn(), isTrue);
    expect(calls.last.queryParameters['bizContent'], contains('"key":"k"'));
    expect(await auth.accessToken(), 'tbdemo-user-token');
  });

  test('pollTicket：票据已被消费 / 过期（800）返回 expired', () async {
    final (auth, _, _) = _auth(poll: neteaseExpiredTicketResponse);

    expect(
      (await auth.pollTicket(
        const NeteaseLoginTicket(url: 'https://163cn.tv/demo', uniKey: 'k'),
      )).status,
      LoginTicketStatus.expired,
    );
  });

  test('未登录时业务令牌回落到匿名令牌', () async {
    final (auth, calls, _) = _auth();

    expect(await auth.accessToken(), isNotEmpty);
    expect(calls.single.path, endsWith('/oauth2/login/anonymous'));
  });

  test('signOut：清空令牌后退回未登录', () async {
    final (auth, _, _) = _auth(token: 'tb-user-token');

    await auth.signOut();

    expect(await auth.loggedIn(), isFalse);
  });
}
