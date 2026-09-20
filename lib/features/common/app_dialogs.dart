import 'package:flutter/cupertino.dart';

/// 通用提示弹窗：单按钮确认。
Future<void> showAppAlert(BuildContext context, String message) {
  return showCupertinoDialog<void>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: const Text('提示'),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('好的'),
        ),
      ],
    ),
  );
}

/// 不可关闭的处理中弹窗；由调用方在完成后 pop。
void showAppProgress(BuildContext context, {String title = '正在生成计划'}) {
  showCupertinoDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CupertinoAlertDialog(
      title: Text(title),
      content: const Padding(
        padding: EdgeInsets.only(top: 16),
        child: CupertinoActivityIndicator(radius: 12),
      ),
    ),
  );
}
