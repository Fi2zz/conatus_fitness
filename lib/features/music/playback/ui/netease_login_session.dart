import 'dart:async';

import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/logging/app_log.dart';
import '../domain/login_ticket.dart';
import '../netease/netease_auth.dart';
import '../netease/netease_exception.dart';

/// 登录会话：申请票据 → 加载授权网页 → 轮询授权结果。
///
/// 与 UI 解耦，页面只管把 [web] / [error] 画出来，并在
/// [onAuthorized] 里收尾（写入令牌这一步由 `NeteaseAuth` 完成）。
class NeteaseLoginSession {
  NeteaseLoginSession({
    required this.auth,
    required this.onChanged,
    required this.onAuthorized,
  });

  /// 轮询间隔：与官方 CLI 一致。
  static const _interval = Duration(seconds: 3);

  final NeteaseAuth auth;

  /// 状态变化（网页就绪 / 出错）时回调，页面据此重绘。
  final void Function() onChanged;

  /// 授权成功回调。
  final void Function() onAuthorized;

  /// 授权网页控制器（就绪前为 null）。
  WebViewController? web;

  /// 打不开登录页时的提示文案。
  String? error;

  /// 最近一次轮询的状态文案（服务端 msg / 错误），页面底部实时显示。
  String? notice;

  NeteaseLoginTicket? _ticket;
  Timer? _timer;

  /// 申请票据并加载网页；票据过期换票时复用。
  Future<void> start() async {
    try {
      final ticket = await auth.requestTicket();
      web = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(ticket.url));
      _ticket = ticket;
      error = null;
      notice = '等待授权…';
      _timer?.cancel();
      _timer = Timer.periodic(_interval, (_) => unawaited(_poll()));
    } on NeteaseException catch (exception, stackTrace) {
      AppLog.error('netease_login', '申请登录票据失败', exception, stackTrace);
      error = exception.message;
    }
    onChanged();
  }

  Future<void> _poll() async {
    final ticket = _ticket;
    if (ticket == null) return;
    try {
      final result = await auth.pollTicket(ticket);
      switch (result.status) {
        case LoginTicketStatus.authorized:
          _timer?.cancel();
          onAuthorized();
          return;
        case LoginTicketStatus.expired:
          _timer?.cancel();
          await start();
          return;
        case LoginTicketStatus.pending:
          // 服务端每个状态都带一句话，原样显示，免得"卡住"看不出原因。
          notice = result.message ?? '等待授权…';
      }
    } on NeteaseException catch (exception, stackTrace) {
      AppLog.warn('netease_login', '轮询授权结果失败', exception, stackTrace);
      notice = '轮询失败：${exception.message}';
    }
    onChanged();
  }

  void dispose() => _timer?.cancel();
}
