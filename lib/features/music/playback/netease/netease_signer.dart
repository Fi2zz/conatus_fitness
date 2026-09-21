import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'netease_key_reader.dart';

/// 开放平台请求签名（RSA_SHA256 / PKCS#1 v1.5）。
///
/// 待签串规则：剔除 sign 与空值 → 参数名按 ASCII 升序 → `k=v` 以 `&` 连接；
/// 用应用私钥做 SHA256withRSA，Base64 即 sign（放进请求时需 URL 编码）。
abstract final class NeteaseSigner {
  /// SHA-256 的 DigestInfo 前缀（RFC 8017 A.2.4）。
  static const _digestInfoPrefix = <int>[
    0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, //
    0x03, 0x04, 0x02, 0x01, 0x05, 0x00, 0x04, 0x20,
  ];

  /// 待签名字符串。
  static String canonical(Map<String, String> params) {
    final keys =
        params.keys
            .where((key) => key != 'sign' && params[key]!.isNotEmpty)
            .toList()
          ..sort();
    return [for (final key in keys) '$key=${params[key]}'].join('&');
  }

  /// 用应用私钥签名，返回 Base64。
  static String sign(String content, String privateKey) {
    final (modulus, exponent) = NeteaseKeyReader.privateKey(privateKey);
    final block = _encode(_digestInfo(content), _size(modulus));
    return base64.encode(_power(block, exponent, modulus));
  }

  /// 用公钥校验签名（本地排查与测试用）。
  static bool verify(String content, String signature, String publicKey) {
    final (modulus, exponent) = NeteaseKeyReader.publicKey(publicKey);
    final recovered = _power(base64.decode(signature), exponent, modulus);
    final expected = _encode(_digestInfo(content), _size(modulus));
    if (recovered.length != expected.length) return false;
    var same = true;
    for (var i = 0; i < expected.length; i++) {
      if (recovered[i] != expected[i]) same = false;
    }
    return same;
  }

  static Uint8List _digestInfo(String content) => Uint8List.fromList([
    ..._digestInfoPrefix,
    ...sha256.convert(utf8.encode(content)).bytes,
  ]);

  static int _size(BigInt modulus) => (modulus.bitLength + 7) ~/ 8;

  /// EMSA-PKCS1-v1_5 填充（RFC 8017 9.2）。
  static Uint8List _encode(Uint8List digestInfo, int size) {
    final block = Uint8List(size);
    block[0] = 0x00;
    block[1] = 0x01;
    final padding = size - digestInfo.length - 3;
    for (var i = 0; i < padding; i++) {
      block[2 + i] = 0xff;
    }
    block[2 + padding] = 0x00;
    block.setRange(3 + padding, size, digestInfo);
    return block;
  }

  /// 模幂：签名用私钥指数，校验用公钥指数。
  static Uint8List _power(Uint8List input, BigInt exponent, BigInt modulus) {
    final value = BigInt.parse(
      _hex(input),
      radix: 16,
    ).modPow(exponent, modulus);
    return _bytes(value.toRadixString(16).padLeft(_size(modulus) * 2, '0'));
  }

  static String _hex(Uint8List bytes) =>
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _bytes(String hex) => Uint8List.fromList([
    for (var i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ]);
}
