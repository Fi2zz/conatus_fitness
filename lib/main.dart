import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'di/app_providers.dart';

void main() {
  // 构建期默认值（--dart-define）：设置页改动落 shared_preferences 并优先生效；
  // 密钥同样经构建期注入，禁止硬编码入库。
  const config = AppConfig(
    llmBaseUrl: String.fromEnvironment(
      'ARK_BASE_URL',
      defaultValue: 'https://ark.cn-beijing.volces.com/api/plan/v3',
    ),
    llmApiKey: String.fromEnvironment('ARK_API_KEY'),
    llmModel: String.fromEnvironment(
      'ARK_MODEL',
      defaultValue: 'doubao-seed-2.0-mini',
    ),
    neteaseAppId: String.fromEnvironment('NETEASE_APP_ID'),
    neteasePrivateKey: String.fromEnvironment('NETEASE_PRIVATE_KEY'),
    neteaseApiBaseUrl: String.fromEnvironment('NETEASE_API_BASE_URL'),
  );
  runApp(
    ProviderScope(
      overrides: [appConfigDefaultsProvider.overrideWithValue(config)],
      child: const FitnessApp(),
    ),
  );
}
