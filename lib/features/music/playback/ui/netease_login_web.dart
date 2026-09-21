import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../common/domain_placeholder.dart';

/// 登录页正文：授权网页 + 状态行；网页未就绪时给加载 / 错误态。
class NeteaseLoginWeb extends StatelessWidget {
  const NeteaseLoginWeb({super.key, this.controller, this.error, this.notice});

  final WebViewController? controller;
  final String? error;

  /// 最近一次轮询状态（服务端原话），让"卡住"能看出原因。
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final String? message = error;
    if (message != null) {
      return DomainPlaceholder(
        icon: CupertinoIcons.exclamationmark_triangle,
        title: '登录页打不开',
        subtitle: message,
      );
    }
    final WebViewController? web = controller;
    if (web == null) return const Center(child: CupertinoActivityIndicator());
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            notice ?? '在页面内登录并同意授权，完成后自动返回',
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
        Expanded(child: WebViewWidget(controller: web)),
      ],
    );
  }
}
