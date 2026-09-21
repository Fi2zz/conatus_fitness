import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import 'app_providers.dart';

/// 持久化键名（snake_case）。
abstract final class _PrefKeys {
  static const llmBaseUrl = 'llm_base_url';
  static const llmModel = 'llm_model';
  static const cloudAsr = 'cloud_asr_enabled';
  static const cloudTts = 'cloud_tts_enabled';
  static const localFirst = 'local_first';
}

/// 运行时配置：启动读盘（首帧为 AsyncLoading），保存即写盘并更新 state。
///
/// 密钥不在此列 —— 归凭据服务（flutter_secure_storage），见 `credentialsProvider`。
class AppConfigNotifier extends AsyncNotifier<AppConfig> {
  @override
  Future<AppConfig> build() async {
    final AppConfig defaults = ref.watch(appConfigDefaultsProvider);
    final SharedPreferences? prefs = await _prefs();
    if (prefs == null) return defaults;
    return defaults.copyWith(
      llmBaseUrl: prefs.getString(_PrefKeys.llmBaseUrl) ?? defaults.llmBaseUrl,
      llmModel: prefs.getString(_PrefKeys.llmModel) ?? defaults.llmModel,
      cloudAsrEnabled:
          prefs.getBool(_PrefKeys.cloudAsr) ?? defaults.cloudAsrEnabled,
      cloudTtsEnabled:
          prefs.getBool(_PrefKeys.cloudTts) ?? defaults.cloudTtsEnabled,
      localFirst: prefs.getBool(_PrefKeys.localFirst) ?? defaults.localFirst,
    );
  }

  /// 保存 LLM 接入配置（baseUrl / model）。
  Future<void> saveLlm({required String baseUrl, required String model}) async {
    final SharedPreferences prefs = await ref.read(
      sharedPreferencesProvider.future,
    );
    await prefs.setString(_PrefKeys.llmBaseUrl, baseUrl);
    await prefs.setString(_PrefKeys.llmModel, model);
    final AppConfig current = state.value ?? ref.read(appConfigDefaultsProvider);
    state = AsyncData(current.copyWith(llmBaseUrl: baseUrl, llmModel: model));
  }

  /// 读盘失败（如插件不可用）时退回编译期默认值，不阻塞启动。
  Future<SharedPreferences?> _prefs() async {
    try {
      return await ref.watch(sharedPreferencesProvider.future);
    } catch (_) {
      return null;
    }
  }
}

/// 运行时配置（shared_preferences 持久化；首帧为 AsyncLoading）。
final appConfigProvider = AsyncNotifierProvider<AppConfigNotifier, AppConfig>(
  AppConfigNotifier.new,
);