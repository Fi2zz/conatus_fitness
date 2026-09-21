import 'dart:async';

import 'package:conatus/conatus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/llm_endpoints.dart';
import '../data/secure_credentials.dart';
import 'app_config_notifier.dart';
import 'app_providers.dart';

/// 凭据服务：注册进 Context（'credentials'），读写 flutter_secure_storage。
///
/// 首次读盘完成后才暴露，故就绪判定不会先看到空快照。编译期回退值只在存储里
/// 没有该键时参与兜底（见 [SecureStorageCredentials]）；三个 Key 各占一个键名，
/// 与三种端点一一对应（见 `llm_endpoints.dart`）。
final credentialsProvider = FutureProvider<Credentials>((ref) async {
  final Context context = ref.watch(agentContextProvider);
  final defaults = ref.watch(appConfigDefaultsProvider);
  final creds = SecureStorageCredentials(
    fallback: <String, String>{
      arkApiKeyName: defaults.llmApiKey,
      agentPlanApiKeyName: defaults.llmAgentPlanApiKey,
      codingPlanApiKeyName: defaults.llmCodingPlanApiKey,
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

/// 当前端点对应的 Key 是否可用：订阅该键的变更流就地更新。
///
/// 用 [Notifier] 而非 `StreamProvider`：后者在重建时会重新订阅，每次重建都退回
/// AsyncLoading，判定方拿不到稳定值。
class ApiKeyReadyNotifier extends Notifier<bool> {
  @override
  bool build() {
    final Credentials? creds = ref.watch(credentialsProvider).value;
    // 端点决定用哪个键：切到 Plan 端点就必须配 Plan 的专属 Key。
    final baseUrl = ref.watch(
      appConfigProvider.select((c) => c.value?.llmBaseUrl ?? ''),
    );
    final keyName = llmCredentialKey(baseUrl);
    if (creds == null) return false;
    final StreamSubscription<Credential> sub = creds.changes.listen((
      Credential credential,
    ) {
      if (credential.key == keyName) state = _hasApiKey(creds, keyName);
    });
    ref.onDispose(sub.cancel);
    return _hasApiKey(creds, keyName);
  }
}

/// 设置页改 key 后立即可见（值不变时不通知依赖方，故不会重建 LLM client）。
final apiKeyReadyProvider = NotifierProvider<ApiKeyReadyNotifier, bool>(
  ApiKeyReadyNotifier.new,
);

bool _hasApiKey(Credentials creds, String keyName) =>
    (creds.get(keyName)?.value.isNotEmpty ?? false);
