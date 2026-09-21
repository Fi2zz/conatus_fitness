import 'dart:convert';
import 'dart:typed_data';

/// 从 PEM / 裸 Base64 的 RSA 密钥里取出模数与指数。
///
/// 开放平台要求 2048 位 pkcs#8 私钥，且常以「去掉头尾与换行的 Base64」下发。
/// 签名只需 n / d（校验只需 n / e），故用极简 DER 读取代替 ASN.1 依赖。
abstract final class NeteaseKeyReader {
  /// 私钥（PKCS#8）→ (modulus, privateExponent)。
  static (BigInt, BigInt) privateKey(String key) {
    final info = _sequence(_der(key)); // PrivateKeyInfo 的字段
    final rsa = _sequence(info[2].content); // OCTET STRING 里是 PKCS#1 的 DER
    return (_integer(rsa[1]), _integer(rsa[3]));
  }

  /// 公钥（X.509 SubjectPublicKeyInfo）→ (modulus, publicExponent)。
  static (BigInt, BigInt) publicKey(String key) {
    final spki = _sequence(_der(key));
    // BIT STRING 首字节是 unused-bits，其后才是 RSAPublicKey 的 DER。
    final rsa = _sequence(spki[1].content.sublist(1));
    return (_integer(rsa[0]), _integer(rsa[1]));
  }

  static Uint8List _der(String key) =>
      base64.decode(key.replaceAll(RegExp(r'-----[\w ]+-----|\s'), ''));

  /// 读出一段 DER 顶层 SEQUENCE 的子节点。
  static List<_Tlv> _sequence(Uint8List der) =>
      _children(_Der(der).read().content);

  static List<_Tlv> _children(Uint8List content) {
    final reader = _Der(content);
    final nodes = <_Tlv>[];
    while (reader.hasMore) {
      nodes.add(reader.read());
    }
    return nodes;
  }

  static BigInt _integer(_Tlv node) => BigInt.parse(
    node.content.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
    radix: 16,
  );
}

/// DER TLV 节点（只用到 tag + 内容）。
class _Tlv {
  const _Tlv(this.content);

  final Uint8List content;
}

/// 极简 DER 游标（覆盖 SEQUENCE / INTEGER / OCTET STRING / BIT STRING 的长度编码）。
class _Der {
  _Der(this._bytes);

  final Uint8List _bytes;
  int _offset = 0;

  bool get hasMore => _offset < _bytes.length;

  _Tlv read() {
    _offset++; // tag：本场景无需区分类型
    var length = _bytes[_offset++];
    if (length & 0x80 != 0) {
      final width = length & 0x7f;
      length = 0;
      for (var i = 0; i < width; i++) {
        length = (length << 8) | _bytes[_offset++];
      }
    }
    final content = Uint8List.sublistView(_bytes, _offset, _offset + length);
    _offset += length;
    return _Tlv(content);
  }
}
