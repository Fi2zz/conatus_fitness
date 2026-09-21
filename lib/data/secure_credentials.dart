import 'package:conatus/conatus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 安全存储凭据来源（flutter_secure_storage）：可写、可读盘、就地推送轮换。
///
/// 构造后需调用 [load] 把存储读进快照；[fallback] 是存储里没有该键时的兜底值
/// （编译期注入的密钥），**不落盘**。写空值等价于清除，快照里会推一条空值记录，
/// 以便订阅方（如 `apiKeyReadyProvider`）观察到「已清除」——
/// 快照本身无法表达移除。
class SecureStorageCredentials extends Credentials {
  SecureStorageCredentials({
    Map<String, String> fallback = const <String, String>{},
  }) : _fallback = <String, Credential>{
         for (final MapEntry<String, String> entry in fallback.entries)
           if (entry.value.isNotEmpty)
             entry.key: Credential(key: entry.key, value: entry.value),
       };

  /// 存储后端；测试用 `FlutterSecureStorage.setMockInitialValues` 替换平台实现。
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Map<String, Credential> _fallback;
  final CredentialSnapshot _snapshot = CredentialSnapshot();

  @override
  List<String> get keys => _snapshot.keys;

  @override
  Stream<Credential> get changes => _snapshot.changes;

  @override
  Credential? get(String key) => _snapshot.get(key);

  /// 读存储入快照；只有存储里缺失的键才用 [fallback] 兜底。
  Future<void> load() async {
    final Map<String, String> stored = await _storage.readAll();
    _snapshot.refreshSnapshot(<String, Credential>{
      for (final MapEntry<String, String> entry in stored.entries)
        entry.key: Credential(key: entry.key, value: entry.value),
      for (final MapEntry<String, Credential> entry in _fallback.entries)
        if (!stored.containsKey(entry.key)) entry.key: entry.value,
    });
  }

  @override
  Future<void> refresh() => load();

  @override
  Future<void> update(String key, String value) async {
    if (value.isEmpty) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
    _snapshot.update(Credential(key: key, value: value));
  }

  @override
  void close() => _snapshot.close();
}
