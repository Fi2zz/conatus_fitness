import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'di/app_providers.dart';

void main() {
  // 密钥经构建期注入（--dart-define），禁止硬编码入库。
  const config = AppConfig(
    llmBaseUrl: String.fromEnvironment('ARK_BASE_URL'),
    llmApiKey: String.fromEnvironment('ARK_API_KEY'),
    llmModel: String.fromEnvironment('ARK_MODEL'),
  );
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const FitnessApp(),
    ),
  );
}
