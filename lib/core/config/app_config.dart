/// 运行时配置缝：LLM 接入与云端开关（架构 14.2 / 16.2）。
///
/// 键值可从环境变量 / flutter_secure_storage 注入，禁止硬编码密钥入库。
class AppConfig {
  const AppConfig({
    this.llmBaseUrl = '',
    this.llmApiKey = '',
    this.llmModel = 'doubao-seed-2.0-mini',
    this.cloudAsrEnabled = false,
    this.cloudTtsEnabled = false,
    this.localFirst = true,
  });

  /// OpenAI 兼容端点（豆包 / DeepSeek / 其他）。
  final String llmBaseUrl;
  final String llmApiKey;
  final String llmModel;

  /// 云端增强开关，默认全关（本地优先，云端调用需显式授权）。
  final bool cloudAsrEnabled;
  final bool cloudTtsEnabled;

  /// 完全本地模式：牺牲部分 AI 能力换取隐私。
  final bool localFirst;

  bool get llmConfigured => llmBaseUrl.isNotEmpty && llmApiKey.isNotEmpty;

  AppConfig copyWith({
    String? llmBaseUrl,
    String? llmApiKey,
    String? llmModel,
    bool? cloudAsrEnabled,
    bool? cloudTtsEnabled,
    bool? localFirst,
  }) {
    return AppConfig(
      llmBaseUrl: llmBaseUrl ?? this.llmBaseUrl,
      llmApiKey: llmApiKey ?? this.llmApiKey,
      llmModel: llmModel ?? this.llmModel,
      cloudAsrEnabled: cloudAsrEnabled ?? this.cloudAsrEnabled,
      cloudTtsEnabled: cloudTtsEnabled ?? this.cloudTtsEnabled,
      localFirst: localFirst ?? this.localFirst,
    );
  }
}
