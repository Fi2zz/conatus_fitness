/// 开放平台请求失败（业务 code 非 200，或响应不可解析）。
class NeteaseException implements Exception {
  const NeteaseException(this.message, {this.needsLogin = false});

  final String message;

  /// 服务端以 301 拒绝（匿名令牌无接口权限）：调用方应引导用户去登录。
  final bool needsLogin;

  @override
  String toString() => 'NeteaseException: $message';
}
