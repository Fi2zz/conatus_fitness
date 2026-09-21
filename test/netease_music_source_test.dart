import 'package:conatus/conatus.dart';
import 'package:conatus_fitness/features/music/playback/domain/track_ref.dart';
import 'package:conatus_fitness/features/music/playback/netease/netease_auth.dart';
import 'package:conatus_fitness/features/music/playback/netease/netease_client.dart';
import 'package:conatus_fitness/features/music/playback/netease/netease_config.dart';
import 'package:conatus_fitness/features/music/playback/netease/netease_device.dart';
import 'package:conatus_fitness/features/music/playback/netease/netease_exception.dart';
import 'package:conatus_fitness/features/music/playback/netease/netease_music_source.dart';
import 'package:conatus_fitness/features/music/playback/netease/netease_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/netease_fixtures.dart';

const _config = NeteaseConfig(
  appId: 'a301010000000000aadb4e5a28b45a67',
  privateKey: neteaseTestPrivateKey,
);

const _track = TrackRef(
  source: 'netease',
  sourceId: '0C2400B1F57E0EB6E24EB4D6357DCC90',
  title: '晴天(深情版)',
  artist: 'Lucky小爱',
);

const _jsonHeaders = <String, String>{
  'content-type': 'application/json; charset=utf-8',
};

/// 假音源：按路径回样例响应，并记录请求 URI。[token] 为已登录的用户令牌。
(NeteaseMusicSource, List<Uri>) _source({
  String detail = neteaseDetailResponse,
  String search = neteaseSearchResponse,
  String profile = neteaseProfileFreeResponse,
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
      if (path.endsWith('/user/profile/get/v2')) {
        return http.Response(profile, 200, headers: _jsonHeaders);
      }
      if (path.endsWith('/search/song/get/v3')) {
        return http.Response(search, 200, headers: _jsonHeaders);
      }
      if (path.endsWith('/song/detail/get/v2')) {
        return http.Response(detail, 200, headers: _jsonHeaders);
      }
      return http.Response(
        '{"code":404,"message":"未知接口"}',
        404,
        headers: _jsonHeaders,
      );
    }),
  );
  final credentials = InMemoryCredentials(
    initial: token == null
        ? const <String, String>{}
        : {NeteaseAuth.tokenKey: token},
  );
  final auth = NeteaseAuth(
    client: client,
    credentials: Future.value(credentials),
  );
  final profileSource = NeteaseProfile(client: client, auth: auth);
  return (NeteaseMusicSource(client, auth, profileSource), calls);
}

void main() {
  test('search：已登录时直接用用户令牌，按官方客户端形状请求', () async {
    final (source, calls) = _source(token: 'tb-user-token');

    final tracks = await source.search('晴天', limit: 3);

    expect(tracks, hasLength(1));
    expect(tracks.single.source, 'netease');
    expect(tracks.single.sourceId, '0C2400B1F57E0EB6E24EB4D6357DCC90');
    expect(tracks.single.title, '晴天(深情版)');
    expect(tracks.single.artist, 'Lucky小爱');

    // 已登录不再走匿名登录。
    expect(calls, hasLength(1));
    expect(calls.single.path, endsWith('/search/song/get/v3'));
    final biz = calls.single.queryParameters['bizContent']!;
    expect(biz, contains('"keyword":"晴天"'));
    expect(biz, contains('"limit":3'));
    expect(biz, contains('"trialScene":"cli"'));
    expect(calls.single.queryParameters['accessToken'], 'tb-user-token');
    expect(calls.single.queryParameters['device'], contains('"os":"ncmcli"'));
    expect(calls.single.queryParameters['sign'], isNotEmpty);
    expect(calls.single.queryParameters['signType'], 'RSA_SHA256');
  });

  test('streamUrl：非会员按 128kbps 取地址（detail 用布尔参数）', () async {
    final (source, calls) = _source(token: 'tb-user-token');

    final uri = await source.streamUrl(_track);

    expect(uri, Uri.parse('http://m802.music.126.net/demo/example.mp3'));
    expect(calls.last.path, endsWith('/song/detail/get/v2'));
    final biz = calls.last.queryParameters['bizContent']!;
    expect(biz, contains('"songId":"0C2400B1F57E0EB6E24EB4D6357DCC90"'));
    expect(biz, contains('"withUrl":true'));
    expect(biz, contains('"bitrate":128'));
  });

  test('streamUrl：会员按 320kbps 取地址', () async {
    final (source, calls) = _source(
      profile: neteaseProfileVipResponse,
      token: 'tb-user-token',
    );

    await source.streamUrl(_track);

    expect(calls.last.queryParameters['bizContent'], contains('"bitrate":320'));
    expect(calls.first.path, endsWith('/user/profile/get/v2'));
  });

  test('streamUrl：VIP 歌 playUrl 为 null 时返回 null', () async {
    final (source, _) = _source(detail: neteaseVipDetailResponse, token: 'tb');

    expect(await source.streamUrl(_track), isNull);
  });

  test('search：artists 为空时回落到 fullArtists（已下线艺人的名字只在这里）', () async {
    const offline = '''
{"code":200,"data":{"recordCount":1,"records":[
{"id":"43B66BE9AD0EC85C6E630B5E24E60CF5","name":"晴天 (原唱 周杰伦)","duration":269000,
"artists":[],"fullArtists":[{"id":null,"name":"RyaVocal"}],"playFlag":true}]}}
''';
    final (source, _) = _source(search: offline, token: 'tb');

    final tracks = await source.search('晴天');

    expect(tracks.single.artist, 'RyaVocal');
  });

  test('search：playFlag 映射成可播标记（false = 开放平台无资源）', () async {
    const mixed = '''
{"code":200,"data":{"recordCount":2,"records":[
{"id":"AAA","name":"Uptown Funk","artists":[{"id":null,"name":"Mark Ronson"}],
"playFlag":false,"vipFlag":false},
{"id":"BBB","name":"晴天(深情版)","artists":[{"id":null,"name":"Lucky小爱"}],
"playFlag":true,"vipFlag":false}]}}
''';
    final (source, _) = _source(search: mixed, token: 'tb');

    final tracks = await source.search('晴天');

    expect(tracks.first.playable, isFalse);
    expect(tracks.last.playable, isTrue);
  });

  test('未登录：匿名令牌被拒（301）时抛 needsLogin 异常', () async {
    final (source, calls) = _source(
      search: '{"code":301,"message":"用户未授权当前接口"}',
    );

    await expectLater(
      source.search('晴天'),
      throwsA(
        isA<NeteaseException>().having((e) => e.needsLogin, 'needsLogin', true),
      ),
    );
    // 先匿名换令牌，再被业务接口拒绝。
    expect(calls.first.path, endsWith('/oauth2/login/anonymous'));
  });

  test('其他业务错误仍抛普通异常', () async {
    final (source, _) = _source(
      search: '{"code":400,"message":"公共参数校验失败"}',
      token: 'tb',
    );

    await expectLater(
      source.search('晴天'),
      throwsA(
        isA<NeteaseException>().having(
          (e) => e.needsLogin,
          'needsLogin',
          false,
        ),
      ),
    );
  });
}
