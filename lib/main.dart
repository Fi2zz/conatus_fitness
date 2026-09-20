import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'di/app_providers.dart';

void main() {
  // 密钥经构建期注入（--dart-define），禁止硬编码入库；base/model 提供默认值。
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
  );
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const FitnessApp(),
    ),
  );
}
