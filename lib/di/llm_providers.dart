import 'package:conatus/conatus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final llm = FallbackLlm([
    DoubaoProvider(
      baseUrl: baseUrl,
      model: model.isEmpty ? null : model,
      credentials: ref.watch(credentialsProvider).requireValue,
    ),
  ]);
  final disposer = provideLlm(context, llm: llm);
  ref.onDispose(() {
    disposer();
    llm.close();
  });
  return context.require<LlmProvider>('llm');
});

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
