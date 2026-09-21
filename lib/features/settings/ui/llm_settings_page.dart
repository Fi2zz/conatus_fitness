import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'llm_connection_test.dart';
import 'llm_settings_actions.dart';
import 'settings_text_field.dart';

/// 模型接入设置页：Base URL / 模型落 shared_preferences，API Key 落安全存储。
/// 保存后即时生效：URL 与模型触发服务重建，Key 由凭据服务就地轮换。
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
    final settings = await loadLlmSettings(ref);
    if (!mounted) return;
    _baseUrl.text = settings.baseUrl;
    _model.text = settings.model;
    _apiKey.text = settings.apiKey;
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
              '普通 API Key 配 /api/v3，套餐 Key 配 /api/plan/v3；Key 只存本机安全存储',
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
            LlmConnectionTest(
              baseUrl: _baseUrl,
              model: _model,
              apiKey: _apiKey,
            ),
            const SizedBox(height: 8),
            CupertinoButton.filled(onPressed: _save, child: const Text('保存')),
          ],
        ),
      ),
    );
  }

  /// 保存：清空 API Key 即删除本机密钥（编译期回退值仍可兜底）。
  Future<void> _save() async {
    await saveLlmSettings(
      ref,
      baseUrl: _baseUrl.text.trim(),
      model: _model.text.trim(),
      apiKey: _apiKey.text.trim(),
    );
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}
