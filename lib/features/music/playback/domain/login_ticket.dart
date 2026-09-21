/// 授权登录票据：用户在网页内登录授权的地址 + 服务端轮询键。
class NeteaseLoginTicket {
  const NeteaseLoginTicket({required this.url, required this.uniKey});

  /// 授权网页地址（由 uniKey + 设备 + appId 在本地拼出，App 内 WebView 打开）。
  final String url;

  /// 轮询键（服务端据此把授权结果与本设备对上）。
  final String uniKey;
}

/// 票据轮询结果。
enum LoginTicketStatus {
  /// 用户还没完成登录 / 授权。
  pending,

  /// 已授权，令牌已拿到。
  authorized,

  /// 票据过期，需要换一张。
  expired,
}

/// 一次轮询的结果：状态 + 服务端给用户看的一句话（如「等待扫码」）。
typedef TicketPoll = ({LoginTicketStatus status, String? message});
