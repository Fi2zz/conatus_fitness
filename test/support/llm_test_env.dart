import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:conatus_fitness/core/config/app_config.dart';
import 'package:conatus_fitness/di/app_config_notifier.dart';
import 'package:conatus_fitness/di/app_providers.dart';
import 'package:conatus_fitness/di/credentials_providers.dart';

/// 已配置的编译期默认值（baseUrl + 回退密钥）。
const configuredDefaults = AppConfig(
  llmBaseUrl: 'https://ark.example/api/v3',
  llmApiKey: 'fallback-key',
  llmModel: 'doubao-seed-2.0-mini',
);

/// 装插件替身：两个存储都经平台通道，不装载则读操作永不返回。
void installPluginMocks() {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  FlutterSecureStorage.setMockInitialValues(<String, String>{});
}

/// 用 [defaults] 作编译期默认值建容器。
ProviderContainer makeContainer({
  AppConfig defaults = configuredDefaults,
}) {
  return ProviderContainer(
    overrides: [appConfigDefaultsProvider.overrideWithValue(defaults)],
  );
}

/// 等配置与凭据都读完盘。
Future<void> settle(ProviderContainer container) async {
  await container.read(appConfigProvider.future);
  await container.read(credentialsProvider.future);
}