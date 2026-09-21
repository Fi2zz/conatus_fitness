import 'package:conatus/conatus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:conatus_fitness/core/config/app_config.dart';
import 'package:conatus_fitness/di/app_providers.dart';
import 'package:conatus_fitness/di/credentials_providers.dart';
import 'package:conatus_fitness/di/llm_providers.dart';

import 'support/llm_test_env.dart';

void main() {
  setUp(installPluginMocks);

  test('改 key 就地生效，不重建 provider', () async {
    final creds = InMemoryCredentials(
      initial: <String, String>{kArkApiKey: 'old'},
    );
    final provider = DoubaoProvider(credentials: creds);
    addTearDown(provider.close);

    expect(provider.apiKey, 'old');
    await creds.update(kArkApiKey, 'new');
    await pumpEventQueue();
    expect(provider.apiKey, 'new');
  });

  test('未配置：状态为 notConfigured，服务为空', () async {
    final container = makeContainer(defaults: const AppConfig());
    addTearDown(container.dispose);

    await settle(container);
    expect(container.read(apiKeyReadyProvider), isFalse);
    expect(container.read(llmStatusProvider), LlmStatus.notConfigured);
    expect(container.read(llmServiceProvider), isNull);
  });

  test('回退密钥 + baseUrl：状态为 ready，服务注册进 Context', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await settle(container);
    final llm = container.read(llmServiceProvider);
    expect(container.read(llmStatusProvider), LlmStatus.ready);
    expect(llm, isNotNull);
    expect(
      container.read(agentContextProvider).require<LlmProvider>('llm'),
      same(llm),
    );
  });

  test('轮换密钥：就地生效，服务实例不重建', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await settle(container);
    final llm = container.read(llmServiceProvider) as FallbackLlm;
    final creds = container.read(credentialsProvider).requireValue;

    await creds.update(kArkApiKey, 'rotated-key');
    await pumpEventQueue();

    expect(container.read(apiKeyReadyProvider), isTrue);
    expect(container.read(llmServiceProvider), same(llm));
    expect((llm.providers.first as DoubaoProvider).apiKey, 'rotated-key');
  });

  test('清空密钥：回到 notConfigured，服务随之下线', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await settle(container);
    final creds = container.read(credentialsProvider).requireValue;
    await creds.update(kArkApiKey, '');
    await pumpEventQueue();

    expect(container.read(apiKeyReadyProvider), isFalse);
    expect(container.read(llmStatusProvider), LlmStatus.notConfigured);
    expect(container.read(llmServiceProvider), isNull);
  });

  test('重建服务不撞 StateError，且替换为新实例', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await settle(container);
    final first = container.read(llmServiceProvider);
    container.invalidate(llmServiceProvider);
    final second = container.read(llmServiceProvider);

    expect(second, isNotNull);
    expect(second, isNot(same(first)));
    expect(
      container.read(agentContextProvider).require<LlmProvider>('llm'),
      same(second),
    );
  });
}
