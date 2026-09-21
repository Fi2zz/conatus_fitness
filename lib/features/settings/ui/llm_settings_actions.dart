import 'package:conatus/conatus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/llm_endpoints.dart';
import '../../../core/logging/app_log.dart';
import '../../../di/app_config_notifier.dart';
import '../../../di/credentials_providers.dart';

/// 普通 API Key 与套餐 Key 的两个端点（Key 不通用）。
const _plainEndpoint = plainArkEndpoint;
const _planEndpoint = agentPlanEndpoint;

/// 读盘回填输入框：Base URL / 模型 / **当前端点的** API Key（切端点即换键）。
Future<({String baseUrl, String model, String apiKey})> loadLlmSettings(
  WidgetRef ref,
) async {
  final config = await ref.read(appConfigProvider.future);
  final creds = await ref.read(credentialsProvider.future);
  final keyName = llmCredentialKey(config.llmBaseUrl);
  return (
    baseUrl: config.llmBaseUrl,
    model: config.llmModel,
    apiKey: creds.get(keyName)?.value ?? '',
  );
}

/// 保存模型接入设置：Base URL / 模型落 shared_preferences，API Key 落安全存储。
Future<void> saveLlmSettings(
  WidgetRef ref, {
  required String baseUrl,
  required String model,
  required String apiKey,
}) async {
  await ref
      .read(appConfigProvider.notifier)
      .saveLlm(baseUrl: baseUrl, model: model);
  final creds = await ref.read(credentialsProvider.future);
  // 写进当前端点的专属键：换端点即换键，三把 Key 互不覆盖。
  await creds.update(llmCredentialKey(baseUrl), apiKey);
}

/// 连通性测试：先试输入框里的端点，认证失败再试另一个常用端点。
///
/// ARK 的普通 API Key 与套餐 Key 走不同端点（`/api/v3` 与 `/api/plan/v3`），
/// 混用会得到 `AuthenticationError`；两个都失败则更像 Key 本身失效 / 复制不全。
Future<String> probeLlm({
  required String baseUrl,
  required String model,
  required String apiKey,
}) async {
  if (baseUrl.isEmpty || apiKey.isEmpty) return 'Base URL 与 API Key 都得填';
  AppLog.info(
    'llm_probe',
    '测试 baseUrl=$baseUrl｜model=${model.isEmpty ? '(框架默认)' : model}'
        '｜key len=${apiKey.length}, ark前缀=${apiKey.startsWith('ark-')}',
  );
  final first = await _ping(baseUrl, model, apiKey);
  if (first.ok) return '✓ 连接正常（$baseUrl）';
  final other = _counterpart(baseUrl);
  if (other == null) return '✗ ${first.message}';
  final second = await _ping(other, model, apiKey);
  if (second.ok) {
    return '✗ 当前端点认证失败，但同一 Key 走 $other 正常 —— 把 Base URL 改成它'
        '（对应键名 ${llmCredentialKey(other)}）';
  }
  return '✗ 两个端点都认证失败（Key 可能已失效或复制不全）：${first.message}';
}

/// 另一个常用端点；输入框里不是这两个之一时返回 null。
String? _counterpart(String baseUrl) {
  if (baseUrl.endsWith('/api/v3')) return _planEndpoint;
  if (baseUrl.endsWith('/api/plan/v3')) return _plainEndpoint;
  return null;
}

Future<({bool ok, String message})> _ping(
  String baseUrl,
  String model,
  String apiKey,
) async {
  final llm = DoubaoProvider(
    baseUrl: baseUrl,
    model: model.isEmpty ? null : model,
    apiKey: apiKey,
  );
  try {
    await llm.chat(const <LlmMessage>[LlmMessage('user', 'ping')]);
    return (ok: true, message: 'ok');
  } on LlmException catch (error, stackTrace) {
    AppLog.error('llm_probe', '端点 $baseUrl 测试失败', error, stackTrace);
    return (ok: false, message: error.message);
  } catch (error) {
    return (ok: false, message: '$error');
  } finally {
    llm.close();
  }
}
