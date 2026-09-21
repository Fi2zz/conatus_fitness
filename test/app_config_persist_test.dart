import 'package:flutter_test/flutter_test.dart';

import 'package:conatus_fitness/core/config/app_config.dart';
import 'package:conatus_fitness/di/app_config_notifier.dart';
import 'package:conatus_fitness/di/app_providers.dart';

import 'support/llm_test_env.dart';

void main() {
  setUp(installPluginMocks);

  test('保存后写盘，新容器读回同一份配置', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(appConfigProvider.future);
    await container
        .read(appConfigProvider.notifier)
        .saveLlm(baseUrl: 'https://next.example/v3', model: 'doubao-pro');

    final prefs = await container.read(sharedPreferencesProvider.future);
    expect(prefs.getString('llm_base_url'), 'https://next.example/v3');
    expect(container.read(appConfigProvider).value?.llmModel, 'doubao-pro');

    final reloaded = makeContainer(defaults: const AppConfig());
    addTearDown(reloaded.dispose);
    final config = await reloaded.read(appConfigProvider.future);
    expect(config.llmBaseUrl, 'https://next.example/v3');
    expect(config.llmModel, 'doubao-pro');
    // 编译期默认值仍在未落盘字段上兜底。
    expect(config.localFirst, isTrue);
  });
}
