import 'package:conatus/conatus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/llm_endpoints.dart';
import '../core/logging/app_log.dart';
import 'app_config_notifier.dart';
import 'app_providers.dart';
import 'credentials_providers.dart';

/// LLM 可用状态（区分「首帧读盘」与「真的未配置」，避免启动闪引导态）。
enum LlmStatus { loading, ready, notConfigured }

/// 框架 LLM 服务：baseUrl 与密钥齐备时构造并注册进 Context（'llm'），否则 null。
///
/// 密钥经 [Credentials] 就地轮换，不重建 client；baseUrl / model 是 final，变更
/// 时本 provider 重建 —— 重建前 Riverpod 会先跑上一次的 `onDispose`，故旧服务
/// （含 HTTP client）先撤销、新服务随后注册，不会撞 `provide` 的 StateError。
final llmServiceProvider = Provider<LlmProvider?>((ref) {
  final (
    loading: bool loading,
    baseUrl: String baseUrl,
    model: String model,
  ) = ref.watch(
    appConfigProvider.select(
      (c) => (
        loading: c.isLoading,
        baseUrl: c.value?.llmBaseUrl ?? '',
        model: c.value?.llmModel ?? '',
      ),
    ),
  );
  final bool keyLoading = ref.watch(
    credentialsProvider.select((c) => c.isLoading),
  );
  if (loading || keyLoading) return null;
  if (baseUrl.isEmpty || !ref.watch(apiKeyReadyProvider)) return null;
  final Context context = ref.watch(agentContextProvider);
  final Credentials creds = ref.watch(credentialsProvider).requireValue;
  // 凭据键按端点选：Plan 端点只认专属 Key（见 llm_endpoints.dart）。
  final credentialKey = llmCredentialKey(baseUrl);
  // 装配即落一行脱敏配置：认证失败时先确认「用的哪份 key、打到哪个端点」。
  AppLog.info(
    'llm',
    '服务装配 baseUrl=$baseUrl｜model=${model.isEmpty ? '(框架默认)' : model}'
        '｜key=$credentialKey(${_keyShape(creds, credentialKey)})',
  );
  final llm = FallbackLlm([
    DoubaoProvider(
      baseUrl: baseUrl,
      model: model.isEmpty ? null : model,
      credentials: creds,
      credentialKey: credentialKey,
    ),
  ]);
  final disposer = provideLlm(context, llm: llm);
  ref.onDispose(() {
    disposer();
    llm.close();
  });
  return context.require<LlmProvider>('llm');
});

/// 密钥形态（不打印值）：长度 + 是否 ARK 前缀，够定位「key 没生效 / 填错」。
String _keyShape(Credentials creds, String keyName) {
  final value = creds.get(keyName)?.value ?? '';
  if (value.isEmpty) return '缺失';
  return 'len=${value.length}, ark前缀=${value.startsWith('ark-')}';
}

/// LLM 可用状态：UI 引导态与 Agent 装配的唯一判定入口。
///
/// 经 [llmServiceProvider] 取值，因此它也承担「确保服务注册进 Context」的角色；
/// 不要在别处直接读 `appConfigProvider` 判定就绪，否则没人触发注册。
final llmStatusProvider = Provider<LlmStatus>((ref) {
  if (ref.watch(llmServiceProvider) != null) return LlmStatus.ready;
  final bool waiting =
      ref.watch(appConfigProvider.select((c) => c.isLoading)) ||
      ref.watch(credentialsProvider.select((c) => c.isLoading));
  return waiting ? LlmStatus.loading : LlmStatus.notConfigured;
});
