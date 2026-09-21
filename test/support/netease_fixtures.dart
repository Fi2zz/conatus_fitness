/// 网易云音源测试夹具。
///
/// 密钥对是一次性生成的**测试专用**材料（不含任何账号凭据，仅用于断言本地
/// 签名/校验结果）；捕获串来自 ncm-cli 0.1.7 的真实请求，用于逐字节比对签名。
library;

const neteaseTestPrivateKey =
    'MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCrnaMvruGtI7lRRVa5ILPhNkcP'
    'pI2siiD2kBKm78ErEfvNnMXmqJIIrcfSyfTf7Z/3qmAYdLnmBa7tRJlIHL+o0rREtaNlsAq/YAl+'
    'YX0pnpb5yeB/IL3XWnRl/B72Lyaf0rpbkuaO7wIlObuil/1Zv3NcQij7KIRYA/7qR7AjLYEUfzB9'
    'TAkWDKTx9jWermLmOlsjmwlHQeizayDxyY5KAz6PQJEG1668VwrzZLTMBQWXEbdVfe9AoOyJdFVI7'
    'GEMhmpcem0PHG9jMHATlmhDo4SEu3aeRy7PA60Rak2sHA1IUZswJJAeRq7Ou6h0JpCDo+Xn3rFKa5'
    '7m0riCfXyLAgMBAAECggEAUxL1djUdSI9U+2rpzqbufHQmVQOukxmwWDqo1MeVhhBoCIG96Oir/Gi'
    'HJNofYDCqsZx3dQ84GAmjQnblDlvgSUxp+CLHLIfZxAcswVFW4clDwzn+ovuJ+k/urZmssTZk55P+I'
    'ysK0aEQNE3srwoNGZ9MLBpYtS/JVMPmZ6l5MaVeFKBx5HaBMF1g7IguUjEpOja5fh7fZaSk/CQEOx'
    'rKOL+uVtQGaNdsL5foC+PCF5ZR86pPJaUGtBSZ+bYxTssb+jPqhlyPHiRk8AdUy2uq/5IgUhm4Km2'
    'PbiDfTKalk0fAY7qWtzyao1SXuQL717adfg4Ul2LE8s5AlSGa9okNDQKBgQDwVMgrqgNH7MYObQgL'
    'QDiPVbAEab0HhOouM8SNR0+tUQoxsi0i46EP3z85sEhBor153bgwKiE9vPKixMJgVnJXRYaYYHjrc'
    'ddhjeq69JxBI72aF7Dlckfw3G/+L6KKTQPd/lRHRs02DBRw7VUF2LLphluvOT4lSVVlNH2NKOTY1Q'
    'KBgQC2zfgs97kFFUJEulEu44/0vkZGb13sjGTWGhzMt1OZPylzQtZLQiIF4/i1XyVkFrZbATPFv58'
    'Bat1eeeK/rTmkQLZG+0AunDA2xzmnNAKy9WUrDGm9hkfP2J1td3H9rIrqRV6167HmgTCjtlxX/9QK'
    'XhtrNORmgDIO0gYm/L+v3wKBgQC6CEayVfYYNNXS0N9LJjkh6qhHojnqmh5UCUp6OdsZRAPqGAwMV'
    '7uS97KPSz+DXx/gN5qd3d7BVYNUL45u2DvGBlF7niG7zvFz2FD8yuAxJCNeJjyOP3oknd4rGmBtQd'
    'RegMJoMgwjbBJen7gSwH0tew15g4vxfOSXZJxTKnaKyQKBgFjtP4JYi9fuLIuUe3Os3dW4TiVrfaxZ'
    '65+/miz4LaHJ+RcJ94cqx7RH3zAT9fOHnPQOVKoo+mfNHZ0c+/I0iWre1A0ZonJKJqYvKlutUHbQK'
    '4PSiQnabcqtXH/o8DnwGq+2SUmEO8mfJRMu3iMs33CfsQTo+Qbn6/ILt1R19aXPAoGAEZ1h4p2FlB'
    'yhlbhiqOvLOTSylgUzUBTXBnBEo7DCS/7pxGSM6w77QTP5q5CtPEgLMuqt9aw4qVFrxmlTEGdoevB'
    'xTFy7JXwgsNy8KhHlyp9W0ELLen+9gCuZT7r95WLhwPRa6x0RUC0ga4z63eTxKrF976DdyJ2/2fb/5'
    'uOuuRc=';

const neteaseTestPublicKey =
    'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAq52jL67hrSO5UUVWuSCz4TZHD6SNrIog9'
    'pASpu/BKxH7zZzF5qiSCK3H0sn03+2f96pgGHS55gWu7USZSBy/qNK0RLWjZbAKv2AJfmF9KZ6W+c'
    'ngfyC911p0Zfwe9i8mn9K6W5Lmju8CJTm7opf9Wb9zXEIo+yiEWAP+6kewIy2BFH8wfUwJFgyk8fY'
    '1nq5i5jpbI5sJR0Hos2sg8cmOSgM+j0CRBteuvFcK82S0zAUFlxG3VX3vQKDsiXRVSOxhDIZqXHpt'
    'DxxvYzBwE5ZoQ6OEhLt2nkcuzwOtEWpNrBwNSFGbMCSQHkauzruodCaQg6Pl596xSmue5tK4gn18i'
    'wIDAQAB';

/// 捕获自 ncm-cli 0.1.7 的一次真实请求（appId 为开放平台文档示例值，
/// 私钥即上面的测试私钥）。
const neteaseCapturedParams = <String, String>{
  'accessToken': 'tb18efe071ff59ebd90b0297327e2629f6b86911b1e25362ae',
  'appId': 'a301010000000000aadb4e5a28b45a67',
  'bizContent': '{"type":2,"expiredKey":"300"}',
  'device':
      '{"deviceType":"openapi","os":"ncmcli","appVer":"0.1.7","channel":"ncmcli",'
      '"model":"Mac_arm64_cli","brand":"ncmcli","osVer":"15.3",'
      '"clientIp":"120.236.240.172","deviceId":"ncmcli_0c3a208d560df59a3c0137a7"}',
  'signType': 'RSA_SHA256',
  'timestamp': '1789959370634',
};

const neteaseCapturedCanonical =
    'accessToken=tb18efe071ff59ebd90b0297327e2629f6b86911b1e25362ae'
    '&appId=a301010000000000aadb4e5a28b45a67'
    '&bizContent={"type":2,"expiredKey":"300"}'
    '&device={"deviceType":"openapi","os":"ncmcli","appVer":"0.1.7",'
    '"channel":"ncmcli","model":"Mac_arm64_cli","brand":"ncmcli","osVer":"15.3",'
    '"clientIp":"120.236.240.172","deviceId":"ncmcli_0c3a208d560df59a3c0137a7"}'
    '&signType=RSA_SHA256&timestamp=1789959370634';

const neteaseCapturedSign =
    'F2h47EED419Ynj1YdjJ7SHDu4EeNRPj0ekIpRFL0hBvIwUMaCMZOW0bDfFO90pBTtASt2BRXEzI7'
    'RvkkxD7KaR9cF5HIS3T232WIHfRUjXC87cDewvXeKs4wFmaCLQXT7iwaWv9POe4O6mgbKi3vZJ1h'
    'aK+BS4OP3aLqVb2XjxihWwfR3KWpJOIdT0JlX9Da0mUKaY15O7Jfyd9oF+jWcYosJ+hKShxiKS9pY'
    'uPmVltbeQTnvySkuY8viXM+95Y7oZQOP5ijVCBS8n+n7uLDLuKQI2eM2tVI+srSR94J3CxtJsFRPA'
    'TDBPazdJqbdln8nyQjAPtmzh3uS1cyX14HQg==';

/// 搜索接口返回样例（字段取自实测响应，做了裁剪）。
const neteaseSearchResponse = '''
{"code":200,"subCode":null,"message":null,"data":{"recordCount":285,"records":[
{"id":"0C2400B1F57E0EB6E24EB4D6357DCC90","name":"晴天(深情版)","duration":278961,
"artists":[{"id":"C60DC27C01CB6E6174CB14CE4160DF8A","name":"Lucky小爱"}],
"album":{"id":"6E2BD6062BCAE39D3481E9A379EAFB72","name":"晴天(深情版)"},
"playFlag":true,"vipFlag":false,"visible":true}]}}
''';

/// detail 接口返回样例（免费歌：有 playUrl）。
const neteaseDetailResponse = '''
{"code":200,"subCode":"200","message":null,"data":{
"id":"0C2400B1F57E0EB6E24EB4D6357DCC90","name":"晴天(深情版)","duration":278961,
"artistName":"Lucky小爱","br":320000,"level":"exhigh","type":"mp3",
"playUrl":"http://m802.music.126.net/demo/example.mp3",
"playUrlExpireTime":1789960749943,"playFlag":true,"vipFlag":false}}
''';

/// detail 接口返回样例（VIP 歌：playUrl 为 null）。
const neteaseVipDetailResponse = '''
{"code":200,"subCode":"200","message":null,"data":{
"id":"A1C22A1440F43C3053E08473AE0926F2","name":"Always Online","playUrl":null,
"playFlag":false,"vipFlag":true}}
''';

/// 匿名登录返回样例。
const neteaseAnonymousLoginResponse = '''
{"code":200,"data":{"accessToken":"tbdemo0000000000000000000000000000000000000000000",
"refreshToken":"wbdemo","expireTime":315360000},"message":""}
''';

/// 授权登录票据返回样例（qrCodeUrl 为页面地址，uniKey 为轮询键）。
const neteaseTicketResponse = '''
{"code":200,"subCode":null,"message":null,"data":
{"qrCodeUrl":"https://163cn.tv/demo","uniKey":"demo-uni-key"}}
''';

/// 轮询授权结果：等待扫码（801）。
const neteasePendingTicketResponse = '''
{"code":200,"data":{"accessToken":null,"status":801,"msg":"等待扫码"},"message":""}
''';

/// 轮询授权结果：已授权（803；实盘中 accessToken 是含 refreshToken 的对象）。
const neteaseAuthorizedTicketResponse = '''
{"code":200,"data":{"accessToken":{"accessToken":"tbdemo-user-token",
"refreshToken":"wbdemo-refresh","expireTime":86400,"scopes":null},
"status":803,"msg":"扫码成功"},"message":""}
''';

/// 轮询授权结果：票据已被消费 / 过期（800）。
const neteaseExpiredTicketResponse = '''
{"code":200,"data":{"accessToken":null,"status":800,
"msg":"二维码不存在或过期, 请刷新"},"message":""}
''';

/// 账号资料（会员有效）：`vipDetail` 有未过期条目（含一条已过期的干扰项）。
const neteaseProfileVipResponse = '''
{"code":200,"subCode":"200","message":null,"data":{"originalId":46323005,
"id":"DB4C2C22D463950C48007B337F77838F","nickname":"afitzz",
"vipDetail":[{"type":6,"expireTime":1},{"type":1,"expireTime":4102444800000}]}}
''';

/// 账号资料（非会员）：`vipDetail` 为空。
const neteaseProfileFreeResponse = '''
{"code":200,"subCode":"200","message":null,"data":{"originalId":46323005,
"id":"DB4C2C22D463950C48007B337F77838F","nickname":"afitzz","vipDetail":[]}}
''';
