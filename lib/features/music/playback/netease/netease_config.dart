/// 网易云音乐开放平台配置（个人开发者认证）。
///
/// 凭据不落库、不进日志：与 LLM 密钥同一口径，只经 env 注入
/// （见 `main.dart` 的 `--dart-define`）。设备信息由 `NeteaseClient` 惰性解析
/// （要读盘，见 `netease_device_store.dart`），故不在此持有。
class NeteaseConfig {
  const NeteaseConfig({
    required this.appId,
    required this.privateKey,
    this.apiBaseUrl = defaultApiBaseUrl,
  });

  /// 实测可用的开放平台域名（文档里的 openapi.* 不是它在服务的域名）。
  static const defaultApiBaseUrl = 'https://openncm.music.163.com';

  /// 控制台的应用 id（非密，可随代码走）。
  final String appId;

  /// 控制台的 PrivateKey（pkcs#8），请求签名用。
  final String privateKey;

  /// 开放平台 API 根地址。
  final String apiBaseUrl;

  /// appId 与私钥齐备才可发起请求。
  bool get isConfigured => appId.isNotEmpty && privateKey.isNotEmpty;
}
