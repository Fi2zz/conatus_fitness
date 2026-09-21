import 'dart:async';

import 'package:conatus/conatus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/secure_credentials.dart';
import 'app_providers.dart';

/// 豆包 / 方舟的密钥键名（与 [DoubaoProvider] 的 `credentialKey` 一致）。
const String kArkApiKey = 'ARK_API_KEY';

/// 凭据服务：注册进 Context（'credentials'），读写 flutter_secure_storage。
///
/// 首次读盘完成后才暴露，故就绪判定不会先看到空快照。编译期回退值只在存储里
/// 没有该键时参与兜底（见 [SecureStorageCredentials]）。
final credentialsProvider = FutureProvider<Credentials>((ref) async {
  final Context context = ref.watch(agentContextProvider);
  final creds = SecureStorageCredentials(
    fallback: <String, String>{
      kArkApiKey: ref.watch(appConfigDefaultsProvider).llmApiKey,
    },
  );
  await creds.load();
  // 不用 provideCredentials：它丢弃 Disposer，重建时会撞 `provide` 的 StateError。
  // 这里保留撤销句柄，等价于它的 `provide + onDispose(close)` 两步。
  final disposer = context.provide('credentials', creds);
  context.onDispose(creds.close);
  ref.onDispose(() {
    disposer();
    creds.close();
  });
  return creds;
});

/// 密钥是否可用：订阅凭据变更流就地更新。
///
/// 用 [Notifier] 而非 `StreamProvider`：后者在重建时会重新订阅，每次重建都退回
/// AsyncLoading，判定方拿不到稳定值。
class ApiKeyReadyNotifier extends Notifier<bool> {
  @override
  bool build() {
    final Credentials? creds = ref.watch(credentialsProvider).value;
    if (creds == null) return false;
    final StreamSubscription<Credential> sub = creds.changes.listen(
      (Credential credential) {
        if (credential.key == kArkApiKey) state = _hasApiKey(creds);
      },
    );
    ref.onDispose(sub.cancel);
    return _hasApiKey(creds);
  }
}

/// 设置页改 key 后立即可见（值不变时不通知依赖方，故不会重建 LLM client）。
final apiKeyReadyProvider = NotifierProvider<ApiKeyReadyNotifier, bool>(
  ApiKeyReadyNotifier.new,
);

bool _hasApiKey(Credentials creds) =>
    (creds.get(kArkApiKey)?.value.isNotEmpty ?? false);