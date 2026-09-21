/// 网易云音乐开放平台配置（个人开发者认证）。
///
/// 凭据不落库、不进日志：与 LLM 密钥同一口径，只经 env 注入
/// （见 `main.dart` 的 `--dart-define`）。
class NeteaseConfig {
  const NeteaseConfig({
    required this.appId,
    required this.privateKey,
    required this.apiBaseUrl,
    this.accessToken,
  });

  /// 控制台的应用 id（非密，可随代码走）。
  final String appId;

  /// 控制台的 PrivateKey，请求签名用。
  final String privateKey;

  /// 开放平台 API 根地址（env 注入，不写死在代码里）。
  final String apiBaseUrl;

  /// 用户授权令牌：由用户 Api 换取，未授权时为 null。
  final String? accessToken;

  /// 三项必填齐备才可发起请求。
  bool get isComplete =>
      appId.isNotEmpty && privateKey.isNotEmpty && apiBaseUrl.isNotEmpty;
}