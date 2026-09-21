/// 运行时配置缝：LLM 接入与云端开关（架构 14.2 / 16.2）。
///
/// [llmApiKey] / [llmAgentPlanApiKey] / [llmCodingPlanApiKey] 都是**编译期回退值**
/// （环境变量注入）：运行时的密钥归凭据服务（flutter_secure_storage）所有，仅在
/// 其为空时用这里的值兜底，且不落盘。三个键对应三种端点（见 `llm_endpoints.dart`）。
/// [llmBaseUrl] / [llmModel] 由设置页改写并持久化到 shared_preferences。
class AppConfig {
  const AppConfig({
    this.llmBaseUrl = '',
    this.llmApiKey = '',
    this.llmAgentPlanApiKey = '',
    this.llmCodingPlanApiKey = '',
    this.llmModel = 'doubao-seed-2.0-mini',
    this.cloudAsrEnabled = false,
    this.cloudTtsEnabled = false,
    this.localFirst = true,
    this.neteaseAppId = '',
    this.neteasePrivateKey = '',
    this.neteaseApiBaseUrl = '',
  });

  /// OpenAI 兼容端点（豆包 / DeepSeek / 其他）。
  final String llmBaseUrl;

  /// 普通方舟 Key（`/api/v3`）。
  final String llmApiKey;

  /// Agent Plan 专属 Key（`/api/plan/v3`）。
  final String llmAgentPlanApiKey;

  /// Coding Plan 专属 Key（`/api/coding/v3`）。
  final String llmCodingPlanApiKey;

  final String llmModel;

  /// 云端增强开关，默认全关（本地优先，云端调用需显式授权）。
  final bool cloudAsrEnabled;
  final bool cloudTtsEnabled;

  /// 完全本地模式：牺牲部分 AI 能力换取隐私。
  final bool localFirst;

  /// 网易云音乐开放平台（个人开发者认证）：appId 非密，privateKey 只经 env
  /// 注入、不落盘（与 [llmApiKey] 同一口径），apiBaseUrl 不写死在代码里。
  final String neteaseAppId;
  final String neteasePrivateKey;
  final String neteaseApiBaseUrl;

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
