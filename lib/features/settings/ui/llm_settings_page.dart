import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/app_config_notifier.dart';
import '../../../di/credentials_providers.dart';
import 'settings_text_field.dart';

/// 模型接入设置页：Base URL / 模型落 shared_preferences，API Key 落安全存储。
///
/// 保存后无需重启：Base URL 与模型触发 LLM 服务重建，API Key 由凭据服务就地轮换。
class LlmSettingsPage extends ConsumerStatefulWidget {
  const LlmSettingsPage({super.key});

  @override
  ConsumerState<LlmSettingsPage> createState() => _LlmSettingsPageState();
}

class _LlmSettingsPageState extends ConsumerState<LlmSettingsPage> {
  final _baseUrl = TextEditingController();
  final _model = TextEditingController();
  final _apiKey = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await ref.read(appConfigProvider.future);
    final creds = await ref.read(credentialsProvider.future);
    if (!mounted) return;
    _baseUrl.text = config.llmBaseUrl;
    _model.text = config.llmModel;
    _apiKey.text = creds.get(kArkApiKey)?.value ?? '';
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _model.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('模型接入')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '模型接入',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const Text(
              'Base URL 与模型保存后即时生效；API Key 只存本机安全存储，不进日志',
              style: TextStyle(color: CupertinoColors.secondaryLabel),
            ),
            const SizedBox(height: 12),
            SettingsTextField(
              controller: _baseUrl,
              label: 'Base URL',
              placeholder: 'https://ark.cn-beijing.volces.com/api/v3',
            ),
            SettingsTextField(
              controller: _model,
              label: '模型',
              placeholder: 'doubao-seed-2.0-mini',
            ),
            SettingsTextField(
              controller: _apiKey,
              label: 'API Key',
              placeholder: 'ARK_API_KEY',
              obscure: true,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(onPressed: _save, child: const Text('保存')),
          ],
        ),
      ),
    );
  }

  /// 保存：清空 API Key 即删除本机密钥（编译期回退值仍可兜底）。
  Future<void> _save() async {
    await ref
        .read(appConfigProvider.notifier)
        .saveLlm(baseUrl: _baseUrl.text.trim(), model: _model.text.trim());
    final creds = await ref.read(credentialsProvider.future);
    await creds.update(kArkApiKey, _apiKey.text.trim());
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // 返回即已保存
  }
}
