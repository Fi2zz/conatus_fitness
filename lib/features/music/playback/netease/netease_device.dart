/// 开放平台公共参数 `device`（设备信息）。
///
/// 网关只认官方客户端的身份三元组：`os` / `channel` / `brand` 必须同为
/// `ncmcli`，否则一律 400「公共参数校验失败，请检查os/channel/brand」；
/// 其余字段取值自由（已用真实请求逐项验证）。故这里不是可自定义的品牌位，
/// 本 App 沿用官方客户端的整套设备值。
class NeteaseDevice {
  const NeteaseDevice({required this.deviceId});

  /// 服务端白名单要求的身份值；登录网页的 `hdw_*` 参数也取这几项。
  static const deviceType = 'openapi';
  static const brand = 'ncmcli';
  static const model = 'Mac_arm64_cli';
  static const _os = 'ncmcli';
  static const _channel = 'ncmcli';
  static const _osVer = '15.3';
  static const _appVer = '0.1.7';
  static const _clientIp = '127.0.0.1';

  /// 本机唯一标识（形如 `conatus_<hex>`）：授权令牌与设备绑定，须跨启动稳定。
  final String deviceId;

  /// 键序与官方客户端一致（便于与实测流量逐字段比对）。
  Map<String, Object?> toJson() => <String, Object?>{
    'deviceType': deviceType,
    'os': _os,
    'appVer': _appVer,
    'channel': _channel,
    'model': model,
    'brand': brand,
    'osVer': _osVer,
    'clientIp': _clientIp,
    'deviceId': deviceId,
  };
}
