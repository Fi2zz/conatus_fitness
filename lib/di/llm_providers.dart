import 'package:conatus/conatus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';

/// LLM 是否已配置（未配置时 UI 显示引导态，不崩溃）。
final llmReadyProvider = Provider<bool>(
  (ref) => ref.watch(appConfigProvider).llmConfigured,
);

/// 框架 DI 上下文：LLM 等基础设施按 Conatus 惯例注册于此。
final agentContextProvider = Provider<Context>((ref) {
  final context = Context.root(name: 'conatus_fitness');
  ref.onDispose(context.dispose);
  return context;
});

/// 框架 LLM 服务：AppConfig 驱动构造，注册进 Context（'llm'）。
final llmServiceProvider = Provider<LlmProvider?>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.llmConfigured) return null;
  final context = ref.watch(agentContextProvider);
  final doubao = DoubaoProvider(
    apiKey: config.llmApiKey,
    baseUrl: config.llmBaseUrl,
    model: config.llmModel.isEmpty ? null : config.llmModel,
  );
  provideLlm(context, llm: FallbackLlm([doubao]));
  return context.require<LlmProvider>('llm');
});
