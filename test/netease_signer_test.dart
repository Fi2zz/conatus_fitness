import 'package:conatus_fitness/features/music/playback/netease/netease_signer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/netease_fixtures.dart';

void main() {
  test('待签串：剔除 sign 与空值，按参数名 ASCII 升序拼接', () {
    final params = Map<String, String>.from(neteaseCapturedParams)
      ..['sign'] = 'ignored'
      ..['blank'] = '';
    expect(NeteaseSigner.canonical(params), neteaseCapturedCanonical);
  });

  test('签名逐字节复现 ncm-cli 的真实请求', () {
    expect(
      NeteaseSigner.sign(neteaseCapturedCanonical, neteaseTestPrivateKey),
      neteaseCapturedSign,
    );
  });

  test('公钥校验：原文通过，改动一个字符即不通过', () {
    expect(
      NeteaseSigner.verify(
        neteaseCapturedCanonical,
        neteaseCapturedSign,
        neteaseTestPublicKey,
      ),
      isTrue,
    );
    expect(
      NeteaseSigner.verify(
        '${neteaseCapturedCanonical}x',
        neteaseCapturedSign,
        neteaseTestPublicKey,
      ),
      isFalse,
    );
  });
}